{
  lib,
  fetchFromGitHub,
  python3,
  runCommand,

  # passthru
  octodns,
}:
let
  # Export `python` with `octodns` as a module for `octodns-providers`.
  python = python3.override {
    self = python;
    packageOverrides = final: prev: {
      octodns = final.toPythonModule octodns;
    };
  };
  python3Packages = python.pkgs;
in
python3Packages.buildPythonApplication rec {
  pname = "octodns";
  version = "1.10.0";
  pyproject = true;

  disabled = python.pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "octodns";
    repo = "octodns";
    tag = "v${version}";
    hash = "sha256-L3c4lYt/fgMctJFArc1XlR+hvpz10kcBcYYXajnNQr0=";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    dnspython
    fqdn
    idna
    natsort
    python-dateutil
    pyyaml
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
  ];

  pythonImportsCheck = [ "octodns" ];

  passthru = {
    providers = lib.recurseIntoAttrs (
      lib.packagesFromDirectoryRecursive {
        inherit (python3Packages) callPackage;
        directory = ./providers;
      }
    );

    withProviders =
      ps:
      let
        pyEnv = python.withPackages ps;
      in
      runCommand "octodns-with-providers" { } ''
        mkdir -p $out/bin
        ln -st $out/bin ${pyEnv}/bin/octodns-*
      '';
  };

  meta = with lib; {
    description = "Tools for managing DNS across multiple providers";
    homepage = "https://github.com/octodns/octodns";
    changelog = "https://github.com/octodns/octodns/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ maintainers.anthonyroussel ];
  };
}
