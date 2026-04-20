# frozen_string_literal: true
#
# Liftman DocuSeal patch — adds /api/templates/pdf.
# Wraps the same Templates::CreateAttachments service the free web UI
# /templates_upload path already uses, but exposes it under token auth.
# Published under AGPL-3.0 at https://github.com/obozkanucla/liftman-docuseal-patches

module Api
  class TemplatesPdfController < ApiBaseController
    def create
      file = params[:file]
      if file.blank?
        return render json: { error: "\"file\" (multipart PDF) is required" },
                      status: :unprocessable_content
      end

      template = Template.new(
        account: current_account,
        author: current_user,
        name: params[:name].presence ||
              File.basename(file.original_filename, ".*"),
        folder: TemplateFolders.find_or_create_by_name(
          current_user,
          params[:folder_name].presence || "API uploads",
        ),
      )

      Templates.maybe_assign_access(template) if Templates.respond_to?(:maybe_assign_access)
      authorize!(:create, template)
      template.save!

      documents, = Templates::CreateAttachments.call(
        template,
        { files: [file] },
        extract_fields: true,
      )
      schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

      if template.fields.blank?
        template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)
        schema.each { |item| item["pending_fields"] = true } if template.fields.present?
      end

      template.update!(schema:)

      WebhookUrls.enqueue_events(template, "template.created")
      SearchEntries.enqueue_reindex(template)

      render json: Templates::SerializeForApi.call(template)
    rescue Templates::CreateAttachments::PdfEncrypted
      render json: { error: "PDF is encrypted" }, status: :unprocessable_content
    end
  end
end
