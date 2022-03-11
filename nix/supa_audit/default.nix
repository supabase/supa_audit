{ stdenv, postgresql }:

stdenv.mkDerivation {
  name = "supa_audit";

  buildInputs = [ postgresql ];

  src = ../../.;

  installPhase = ''
    install -D -t $out/share/postgresql/extension *.sql
    install -D -t $out/share/postgresql/extension *.control
  '';
}
