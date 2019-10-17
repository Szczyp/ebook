{ fetchurl, fetchgit, linkFarm, runCommandNoCC, gnutar }: rec {
  offline_cache = linkFarm "offline" packages;
  packages = [
    {
      name = "bindings___bindings_1.5.0.tgz";
      path = fetchurl {
        name = "bindings___bindings_1.5.0.tgz";
        url  = "https://registry.yarnpkg.com/bindings/-/bindings-1.5.0.tgz";
        sha1 = "10353c9e945334bc0511a6d90b38fbc7c9c504df";
      };
    }
    {
      name = "collapse_white_space___collapse_white_space_1.0.5.tgz";
      path = fetchurl {
        name = "collapse_white_space___collapse_white_space_1.0.5.tgz";
        url  = "https://registry.yarnpkg.com/collapse-white-space/-/collapse-white-space-1.0.5.tgz";
        sha1 = "c2495b699ab1ed380d29a1091e01063e75dbbe3a";
      };
    }
    {
      name = "file_uri_to_path___file_uri_to_path_1.0.0.tgz";
      path = fetchurl {
        name = "file_uri_to_path___file_uri_to_path_1.0.0.tgz";
        url  = "https://registry.yarnpkg.com/file-uri-to-path/-/file-uri-to-path-1.0.0.tgz";
        sha1 = "553a7b8446ff6f684359c445f1e37a05dacc33dd";
      };
    }
    {
      name = "franc___franc_4.1.0.tgz";
      path = fetchurl {
        name = "franc___franc_4.1.0.tgz";
        url  = "https://registry.yarnpkg.com/franc/-/franc-4.1.0.tgz";
        sha1 = "81bc0b222ab6c13b972c4254d9002e7a48038539";
      };
    }
    {
      name = "he___he_1.1.1.tgz";
      path = fetchurl {
        name = "he___he_1.1.1.tgz";
        url  = "https://registry.yarnpkg.com/he/-/he-1.1.1.tgz";
        sha1 = "93410fd21b009735151f8868c2f271f3427e23fd";
      };
    }
    {
      name = "n_gram___n_gram_1.1.1.tgz";
      path = fetchurl {
        name = "n_gram___n_gram_1.1.1.tgz";
        url  = "https://registry.yarnpkg.com/n-gram/-/n-gram-1.1.1.tgz";
        sha1 = "a374dc176a9063a2388d1be18ed7c35828be2a97";
      };
    }
    {
      name = "nan___nan_2.14.0.tgz";
      path = fetchurl {
        name = "nan___nan_2.14.0.tgz";
        url  = "https://registry.yarnpkg.com/nan/-/nan-2.14.0.tgz";
        sha1 = "7818f722027b2459a86f0295d434d1fc2336c52c";
      };
    }
    {
      name = "node_html_parser___node_html_parser_1.1.16.tgz";
      path = fetchurl {
        name = "node_html_parser___node_html_parser_1.1.16.tgz";
        url  = "https://registry.yarnpkg.com/node-html-parser/-/node-html-parser-1.1.16.tgz";
        sha1 = "59f072bcabf1cf6e23f7878a76e0c3b81b9194fa";
      };
    }
    {
      name = "71257e6ffe90d4beea089aa3347416e2b4e69ea9";
      path = fetchurl {
        name = "https___codeload.github.com_Szczyp_node_rdkafka_tar.gz_71257e6ffe90d4beea089aa3347416e2b4e69ea9";
        url  = "https://codeload.github.com/Szczyp/node-rdkafka/tar.gz/71257e6ffe90d4beea089aa3347416e2b4e69ea9";
        sha1 = "158396ee1cd3fbb9da637106fdb88b7802304c51";
      };
    }
    {
      name = "trigram_utils___trigram_utils_1.0.2.tgz";
      path = fetchurl {
        name = "trigram_utils___trigram_utils_1.0.2.tgz";
        url  = "https://registry.yarnpkg.com/trigram-utils/-/trigram-utils-1.0.2.tgz";
        sha1 = "47574b7fade636e0fc06515788cbbd61786d2292";
      };
    }
    {
      name = "trim___trim_0.0.1.tgz";
      path = fetchurl {
        name = "trim___trim_0.0.1.tgz";
        url  = "https://registry.yarnpkg.com/trim/-/trim-0.0.1.tgz";
        sha1 = "5858547f6b290757ee95cccc666fb50084c460dd";
      };
    }
  ];
}
