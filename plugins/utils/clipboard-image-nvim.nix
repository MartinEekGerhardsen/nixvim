{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.plugins.clipboard-image;
in {
  meta.maintainers = [maintainers.MartinEekGerhardsen];

  options.plugins.clipboard-image =
    helpers.extraOptionsOptions
    // {
      enable = mkEnableOption "clipboard-image.nvim";

      package = helpers.mkPackageOption "clipboard-image.nvim" pkgs.vimPlugins.clipboard-image-nvim; # TODO replace

      filetypes = with types; let
        filetypesType = submodule {
          options = {
            imgDir =
              helpers.mkNullOrOption
              (either str (listOf str))
              ''
                Directory where the image from clipboard will be copied to.
                The directory will be created relative to the current
                working directory. To get a path relative to the
                current file: `["%:p:h" "images"]`
              '';

            imgDirTxt =
              helpers.mkNullOrOption
              str
              ''
                Directory that will be inserted to buffer.
                Example: Your actual dir is `src/assets/img` but your dir
                on **text** or buffer is `/assets/img`'';

            imgName =
              helpers.mkNullOrOption
              helpers.nixvimTypes.rawLua
              ''
                Image's name. A lua function returning the filename of the image.
                Example: `"function() return os.date('%Y-%m-%dT%H:%M:%S%z') end"`
              '';

            imgHandler =
              helpers.mkNullOrOption
              helpers.nixvimTypes.rawLua
              ''
                Function that will handle image after pasted.
                `img` is a table that contain pasted image's `name` and `path`
              '';

            affix =
              helpers.mkNullOrOption
              str
              "String that sandwiched the image's path";
          };
        };
      in
        mkOption {
          type = with types; attrsOf filetypesType;

          default = {};

          example = {
            default = {
              imgDir = "img";
              imgDirTxt = "img";
              imgName.__raw = "function() return os.date('%Y-%m-%d-%H-%M-%S') end";
              imgHandler.__raw = "function(img)  end";
              affix = "%s";
            };

            markdown.affix = "![](%s)";

            asciidoc.affix = "image::%s[]";

            norg = {
              imgDir = ["%:p:h" "images"];
              imgDirTxt = "./images";
              imgName.__raw = "function() return os.date('%Y-%m-%dT%H:%M:%S%z') end";
              affix = ".image %s";
            };
          };

          description = "Configuration of image paste for different filetypes.";
        };
    };

  config = mkIf cfg.enable {
    extraPlugins = [cfg.package];

    extraConfigLua = let
      setupOptions = with cfg;
        mapAttrs
        (
          filetype: filetypeAttrs:
            with filetypeAttrs; {
              img_dir = imgDir;
              img_dir_txt = imgDirTxt;
              img_name = imgName;
              img_handler = imgHandler;
              inherit affix;
            }
        )
        cfg.filetypes;
    in ''
      require('clipboard-image').setup(${helpers.toLuaObject setupOptions})
    '';
  };
}
