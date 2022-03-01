{ stdenv, postgresql }:

stdenv.mkDerivation {
  name = "supa_audit";

  buildInputs = [ postgresql ];

  src = ../../.;

  installPhase = ''
    install -D -t $out/share/postgresql/extension supa_audit--0.2.0.sql
    install -D -t $out/share/postgresql/extension supa_audit--0.1.0--0.2.0.sql
    install -D -t $out/share/postgresql/extension supa_audit.control
  '';
}
