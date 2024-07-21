{
  buildPythonPackage,
  cliff,
  fetchFromGitea,
  keystoneauth1,
  lib,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  pbr,
  requests-mock,
  requests,
  setuptools,
  stestr,
}:

buildPythonPackage rec {
  pname = "python-barbicanclient";
  version = "7.0.0";
  pyproject = true;

  src = fetchFromGitea {
    domain = "opendev.org";
    owner = "openstack";
    repo = "python-barbicanclient";
    rev = version;
    hash = "sha256-odoYyBulOQkjUpymFyZgvI+DYmdHJY3PaG8hh2ms+/0=";
  };

  env.PBR_VERSION = version;

  build-system = [
    pbr
    setuptools
  ];

  dependencies = [
    cliff
    keystoneauth1
    oslo-i18n
    oslo-serialization
    oslo-utils
    requests
  ];

  doCheck = true;

  nativeCheckInputs = [
    requests-mock
    stestr
  ];

  checkPhase = ''
    stestr run
  '';

  pythonImportsCheck = [ "barbicanclient" ];

  meta = {
    homepage = "https://opendev.org/openstack/python-barbicanclient";
    description = "Client library for OpenStack Barbican API";
    license = lib.licenses.asl20;
    maintainers = lib.teams.openstack.members ++ (with lib.maintainers; [ anthonyroussel ]);
  };
}
