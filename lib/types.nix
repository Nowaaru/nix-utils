{
 types,
 strings,
 ...
}: rec {
  image = with types;
    mkOptionType {
      name = "image";

      description = "an image with an extension";
      descriptionClass = "noun";

      check = x:
        builtins.isString x;
    };

  imageWithExt = ext:
    image
    // {
      description = "image with ${ext} extension";
      check = x:
        (image.check x)
        && strings.hasSuffix ext x;
    };
}
