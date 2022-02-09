let
  nixpkgs = builtins.fetchTarball {
    name = "2021-12";
    url = "https://github.com/NixOS/nixpkgs/archive/5f8babdd259d68ff8052dfc8d650ebdf9cc3bd75.tar.gz";
  };
in with import nixpkgs {};
mkShell {
  buildInputs =
    let
      pgWithExt = { pg }: pg.withPackages (p: [ (callPackage ./nix/supa_audit { postgresql = pg; }) ]);
      pg13WithExt = pgWithExt { pg = postgresql_13; };
      pg_w_supa_audit = callPackage ./nix/supa_audit/pgScript.nix { postgresql = pg13WithExt; };
    in
    [ pg_w_supa_audit ];
}
