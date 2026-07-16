--- Acceptance suite for the Java "empty" service archetype: a platform overlay that renders ONLY the
--- servicing layer - CI/CD, Kubernetes platform manifests, container builds, and repo hygiene files -
--- in place at the destination root, with no project scaffolding and no domain code. This suite
--- verifies exactly that: the platform files render, the manifests parse, and no Maven/Java project is
--- produced.
---
--- Run from the archetype repo root (uses ./prova.toml):   prova
--- There is nothing to build or boot - the overlay carries no code.

local SRC = "."

local ANSWERS = {
  author_name    = "Test Author",
  author_email   = "test@example.com",
  org_name       = "acme",
  solution_name  = "platform",
  prefix_name    = "Example",
  suffix_name    = "Service",
  image_registry = "ghcr.io/acme",
  persistence    = "None",
}

-- The platform/servicing files the overlay must produce (rendered in place at the destination root).
local EXPECTED_FILES = {
  ".editorconfig",
  ".gitattributes",
  ".gitignore",
  ".github/workflows/build.yaml",
  ".github/workflows/cut-tag.yaml",
  ".platform/docker/local/Dockerfile",
  ".platform/docker/prd/Dockerfile",
  ".platform/kubernetes/base/application.yaml",
  ".platform/kubernetes/base/kustomization.yaml",
  ".platform/kubernetes/dev/kustomization.yaml",
  ".platform/kubernetes/prd/kustomization.yaml",
}

-- Proof it stays an overlay: no project scaffold is rendered.
local ABSENT_FILES = {
  "pom.xml",
  "example-service/pom.xml",
  "example-service-server/pom.xml",
}

archetect.verify{
  name = "java-empty",
  source = SRC,
  answers = ANSWERS,
  expected_files = EXPECTED_FILES,
  absent_files = ABSENT_FILES,
  yaml_globs = { ".platform/kubernetes/**/*.yaml" },
}
