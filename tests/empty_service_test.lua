--- Acceptance suite for the Java "empty" service archetype: a platform overlay that renders ONLY the
--- servicing layer - CI/CD, Kubernetes platform manifests, container builds, and repo hygiene files -
--- in place at the destination root, with no project scaffolding and no domain code. This suite
--- verifies exactly that: the platform files render, the manifests parse, and no Maven/Java project is
--- produced.
---
--- Run from the archetype repo root (uses ./prova.toml):   prova
--- requires archetect; skips cleanly without it. There is nothing to build or boot - the overlay
--- carries no code.
---
--- Rendering shells out to the `archetect` CLI (one fresh process per render) rather than the
--- in-process `archetect.render`, which can only render once per process.

local SRC = "."   -- shell.run inherits prova's cwd (the repo root), where the archetype lives

local function answers_yaml()
  return table.concat({
    'author_name: "Test Author"',
    'author_email: "test@example.com"',
    'org_name: "acme"',
    'solution_name: "platform"',
    'prefix_name: "Example"',
    'suffix_name: "Service"',
    'image_registry: "ghcr.io/acme"',
    'persistence: "None"',
  }, "\n") .. "\n"
end

-- The overlay renders in place at the destination root - there is no project-name subdirectory.
local function render(ctx)
  local out     = ctx:tempdir()
  local answers = out .. "/answers.yaml"
  fs.write(answers, answers_yaml())
  shell.run("archetect render " .. SRC .. " " .. out .. "/rendered -A " .. answers .. " -D --headless",
    { timeout = "180s", check = true })
  return out .. "/rendered"
end

-- The platform/servicing files the overlay must produce.
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

local project = prova.fixture("java-empty:project", Scope.File, function(ctx)
  return render(ctx)
end)

prova.group("java-empty", { requires = { "archetect" } }, function(g)
  g:test("renders the platform overlay in place", function(t)
    local root = t:use(project)
    t:expect_all(function()
      for _, f in ipairs(EXPECTED_FILES) do
        t:expect(fs.exists(root .. "/" .. f), f):is_true()
      end
      for _, f in ipairs(ABSENT_FILES) do
        t:expect(fs.exists(root .. "/" .. f), f .. " (should be absent)"):is_false()
      end
    end)
  end)

  g:test("platform kubernetes manifests parse", function(t)
    local root = t:use(project)
    local matches = fs.glob(root, ".platform/kubernetes/**/*.yaml")
    t:expect(#matches, "kubernetes manifests"):never():equals(0)
    for _, path in ipairs(matches) do
      yaml.parse_all(fs.read(path))
    end
  end)
end)
