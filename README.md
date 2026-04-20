# liftman-docuseal-patches

Meadows Forklifts / Liftman AGPL-compliance source offer for the patched DocuSeal Docker image run as the e-signature service for the Liftman platform (DESIGN-004).

## Why this repo exists

Liftman is a Django application that uses DocuSeal (AGPL-3.0) as a self-hosted e-signature service. We run our own modified build of the upstream Docker image on our VPS. AGPL-3.0 section 13 (network modification) requires that users who interact with modified AGPL software over a network be able to obtain the modified source. Signers interact with our DocuSeal instance via emailed signing links, so this repository is our source offer under that clause.

## Upstream and licence

DocuSeal is licensed under GNU AGPL-3.0 with a single additional term (section 7(b)): a covered work must retain the original DocuSeal attribution in interactive user interfaces. We preserve that attribution unchanged. Nothing in our patches alters, removes, or obscures DocuSeal branding in DocuSeal UI surfaces.

## What the patch does

Adds one new API endpoint, `POST /api/templates/pdf`, which accepts a multipart PDF upload with an `X-Auth-Token` header and creates a DocuSeal Template in the authenticated user account. The endpoint is an API-token wrapper over the existing `Templates::CreateAttachments` Rails service that the upstream free web UI `/templates_upload` form already uses. We do not implement any other Pro Edition features, nor remove any upstream functionality.

The missing route is injected into the existing `:api` namespace in `config/routes.rb`, and the existing `ApiPathConsiderJsonMiddleware` is extended to whitelist the new path (its force-JSON-parse behaviour breaks multipart uploads otherwise; this mirrors the existing `/api/attachments` whitelist upstream).

## How to build

```
docker build -t docuseal-liftman:latest .
docker run ... docuseal-liftman:latest
```

The resulting image behaves identically to `docuseal/docuseal:latest` except `POST /api/templates/pdf` returns the created template JSON instead of a Pro Edition 404.

## Files

- `Dockerfile` — FROM docuseal/docuseal:latest + patch COPY + routes/middleware sed.
- `app/controllers/api/templates_pdf_controller.rb` — new Rails controller, about 40 lines.

## Running instance

The patched image is deployed at Meadows Forklifts' staging and production VPS as part of the Liftman platform. DocuSeal branding and links to the upstream project are retained in the UI as required by section 7(b).

## Contact

For AGPL source requests or questions about these patches, open an issue here or email oburako@gmail.com.
