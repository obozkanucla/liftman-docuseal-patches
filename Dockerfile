FROM docuseal/docuseal:latest

# Liftman patch — adds /api/templates/pdf endpoint that wraps the existing
# Templates::CreateAttachments service (used by the free web UI upload
# path) behind X-Auth-Token auth. AGPL-compliant. Source:
# https://github.com/obozkanucla/liftman-docuseal-patches

COPY patches/templates_pdf_controller.rb /app/app/controllers/api/templates_pdf_controller.rb

# Inject route inside the existing :api namespace (line after the opener)
RUN sed -i "/namespace :api, defaults: { format: :json } do/a\\    post 'templates/pdf', to: 'templates_pdf#create'" /app/config/routes.rb

# Whitelist our path in ApiPathConsiderJsonMiddleware so multipart body
# isn't forced to be parsed as JSON (mirrors the existing /attachments,
# /documents whitelist).
RUN sed -i "s|!env\\['PATH_INFO'\\].ends_with?('/attachments') \&\&|!env['PATH_INFO'].ends_with?('/attachments') \&\&\n       !env['PATH_INFO'].ends_with?('/templates/pdf') \&\&|" /app/lib/api_path_consider_json_middleware.rb
