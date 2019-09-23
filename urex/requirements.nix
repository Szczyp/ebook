# generated using pypi2nix tool (version: 2.0.0)
# See more at: https://github.com/nix-community/pypi2nix
#
# COMMAND:
#   pypi2nix -r requirements.txt -r requirements-dev.txt -V 3.7
#

{ pkgs ? import <nixpkgs> {},
  overrides ? ({ pkgs, python }: self: super: {})
}:

let

  inherit (pkgs) makeWrapper;
  inherit (pkgs.stdenv.lib) fix' extends inNixShell;

  pythonPackages =
  import "${toString pkgs.path}/pkgs/top-level/python-packages.nix" {
    inherit pkgs;
    inherit (pkgs) stdenv;
    python = pkgs.python37;
    # patching pip so it does not try to remove files when running nix-shell
    overrides =
      self: super: {
        bootstrapped-pip = super.bootstrapped-pip.overrideDerivation (old: {
          patchPhase = old.patchPhase + ''
            if [ -e $out/${pkgs.python37.sitePackages}/pip/req/req_install.py ]; then
              sed -i \
                -e "s|paths_to_remove.remove(auto_confirm)|#paths_to_remove.remove(auto_confirm)|"  \
                -e "s|self.uninstalled = paths_to_remove|#self.uninstalled = paths_to_remove|"  \
                $out/${pkgs.python37.sitePackages}/pip/req/req_install.py
            fi
          '';
        });
      };
  };

  commonBuildInputs = [];
  commonDoCheck = false;

  withPackages = pkgs':
    let
      pkgs = builtins.removeAttrs pkgs' ["__unfix__"];
      interpreterWithPackages = selectPkgsFn: pythonPackages.buildPythonPackage {
        name = "python37-interpreter";
        buildInputs = [ makeWrapper ] ++ (selectPkgsFn pkgs);
        buildCommand = ''
          mkdir -p $out/bin
          ln -s ${pythonPackages.python.interpreter} \
              $out/bin/${pythonPackages.python.executable}
          for dep in ${builtins.concatStringsSep " "
              (selectPkgsFn pkgs)}; do
            if [ -d "$dep/bin" ]; then
              for prog in "$dep/bin/"*; do
                if [ -x "$prog" ] && [ -f "$prog" ]; then
                  ln -s $prog $out/bin/`basename $prog`
                fi
              done
            fi
          done
          for prog in "$out/bin/"*; do
            wrapProgram "$prog" --prefix PYTHONPATH : "$PYTHONPATH"
          done
          pushd $out/bin
          ln -s ${pythonPackages.python.executable} python
          ln -s ${pythonPackages.python.executable} \
              python3
          popd
        '';
        passthru.interpreter = pythonPackages.python;
      };

      interpreter = interpreterWithPackages builtins.attrValues;
    in {
      __old = pythonPackages;
      inherit interpreter;
      inherit interpreterWithPackages;
      mkDerivation = args: pythonPackages.buildPythonPackage (args // {
        nativeBuildInputs = (args.nativeBuildInputs or []) ++ args.buildInputs;
      });
      packages = pkgs;
      overrideDerivation = drv: f:
        pythonPackages.buildPythonPackage (
          drv.drvAttrs // f drv.drvAttrs // { meta = drv.meta; }
        );
      withPackages = pkgs'':
        withPackages (pkgs // pkgs'');
    };

  python = withPackages {};

  generated = self: {
    "appdirs" = python.mkDerivation {
      name = "appdirs-1.4.3";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/48/69/d87c60746b393309ca30761f8e2b49473d43450b150cb08f3c6df5c11be5/appdirs-1.4.3.tar.gz";
        sha256 = "9e5896d1372858f8dd3344faf4e5014d21849c756c8d5701f78f8a103b372d92";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "http://github.com/ActiveState/appdirs";
        license = licenses.mit;
        description = "A small Python module for determining appropriate platform-specific dirs, e.g. a \"user data dir\".";
      };
    };

    "autoflake" = python.mkDerivation {
      name = "autoflake-1.3.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/88/88/9a8ae06cc31f68b26078cbbef50ae5df361f4ac0efaafbf03a9fa79ca9c5/autoflake-1.3.1.tar.gz";
        sha256 = "680cb9dade101ed647488238ccb8b8bfb4369b53d58ba2c8cdf7d5d54e01f95b";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."pyflakes"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/myint/autoflake";
        license = "Expat License";
        description = "Removes unused imports and unused variables";
      };
    };

    "certifi" = python.mkDerivation {
      name = "certifi-2019.9.11";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/62/85/7585750fd65599e88df0fed59c74f5075d4ea2fe611deceb95dd1c2fb25b/certifi-2019.9.11.tar.gz";
        sha256 = "e4f3620cfea4f83eedc95b24abd9cd56f3c4b146dd0177e83a21b4eb49e21e50";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://certifi.io/";
        license = licenses.mpl20;
        description = "Python package for providing Mozilla's CA Bundle.";
      };
    };

    "chardet" = python.mkDerivation {
      name = "chardet-3.0.4";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/fc/bb/a5768c230f9ddb03acc9ef3f0d4a3cf93462473795d18e9535498c8f929d/chardet-3.0.4.tar.gz";
        sha256 = "84ab92ed1c4d4f16916e05906b6b75a6c0fb5db821cc65e70cbd64a3e2a5eaae";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/chardet/chardet";
        license = licenses.lgpl3;
        description = "Universal encoding detector for Python 2 and 3";
      };
    };

    "docutils" = python.mkDerivation {
      name = "docutils-0.15.2";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/93/22/953e071b589b0b1fee420ab06a0d15e5aa0c7470eb9966d60393ce58ad61/docutils-0.15.2.tar.gz";
        sha256 = "a2aeea129088da402665e92e0b25b04b073c04b2dce4ab65caaa38b7ce2e1a99";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "http://docutils.sourceforge.net/";
        license = "public domain, Python, 2-Clause BSD, GPL 3 (see COPYING.txt)";
        description = "Docutils -- Python Documentation Utilities";
      };
    };

    "entrypoints" = python.mkDerivation {
      name = "entrypoints-0.3";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/b4/ef/063484f1f9ba3081e920ec9972c96664e2edb9fdc3d8669b0e3b8fc0ad7c/entrypoints-0.3.tar.gz";
        sha256 = "c70dd71abe5a8c85e55e12c19bd91ccfeec11a6e99044204511f9ed547d48451";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [
        self."flit"
      ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/takluyver/entrypoints";
        license = "UNKNOWN";
        description = "Discover and load entry points from installed packages.";
      };
    };

    "flake8" = python.mkDerivation {
      name = "flake8-3.7.8";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/8d/a7/99222c9200af533c1ecb1120d99adbd1c033b57296ac5cb39d121db007a8/flake8-3.7.8.tar.gz";
        sha256 = "19241c1cbc971b9962473e4438a2ca19749a7dd002dd1a946eaba171b4114548";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."entrypoints"
        self."mccabe"
        self."pycodestyle"
        self."pyflakes"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://gitlab.com/pycqa/flake8";
        license = licenses.mit;
        description = "the modular source code checker: pep8, pyflakes and co";
      };
    };

    "flit" = python.mkDerivation {
      name = "flit-1.3";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/1f/87/9ea76ab4cdf1fd36710d9688ec36a0053067c47e753b32272f952ff206c5/flit-1.3.tar.gz";
        sha256 = "6f6f0fb83c51ffa3a150fa41b5ac118df9ea4a87c2c06dff4ebf9adbe7b52b36";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [
        self."docutils"
        self."intreehooks"
        self."pytoml"
        self."requests"
      ];
      propagatedBuildInputs = [
        self."docutils"
        self."pytoml"
        self."requests"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/takluyver/flit";
        license = "UNKNOWN";
        description = "A simple packaging tool for simple packages.";
      };
    };

    "idna" = python.mkDerivation {
      name = "idna-2.8";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/ad/13/eb56951b6f7950cadb579ca166e448ba77f9d24efc03edd7e55fa57d04b7/idna-2.8.tar.gz";
        sha256 = "c357b3f628cf53ae2c4c05627ecc484553142ca23264e593d327bcde5e9c3407";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/kjd/idna";
        license = licenses.bsdOriginal;
        description = "Internationalized Domain Names in Applications (IDNA)";
      };
    };

    "importmagic3" = python.mkDerivation {
      name = "importmagic3-0.2.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/3a/93/2ff8de19df9dfbf20ba5a5e2a4649b5391bdca45dab09f34d49ea5043fea/importmagic3-0.2.0.tar.gz";
        sha256 = "b4ab36e1a9003b01dfbbac97b78201df1ae413d7f4c8eaf09f40423c720f8b46";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/paradoxxxzero/importmagic";
        license = licenses.bsdOriginal;
        description = "Fork of Python Import Magic - automagically add, remove and manage imports.";
      };
    };

    "intreehooks" = python.mkDerivation {
      name = "intreehooks-1.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/f9/a5/5dacebf93232a847970921af2b020f9f2a8e0064e3a97727cd38efc77ba0/intreehooks-1.0.tar.gz";
        sha256 = "87e600d3b16b97ed219c078681260639e77ef5a17c0e0dbdd5a302f99b4e34e1";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."pytoml"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/takluyver/intreehooks";
        license = "UNKNOWN";
        description = "Load a PEP 517 backend from inside the source tree";
      };
    };

    "jedi" = python.mkDerivation {
      name = "jedi-0.15.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/85/03/cd5a6e44a5753b4d539288d9d1f9645caac889c17dd2950292a8818f86b2/jedi-0.15.1.tar.gz";
        sha256 = "ba859c74fa3c966a22f2aeebe1b74ee27e2a462f56d3f5f7ca4a59af61bfe42e";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."parso"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/davidhalter/jedi";
        license = licenses.mit;
        description = "An autocompletion tool for Python that can be used for text editors.";
      };
    };

    "json-rpc" = python.mkDerivation {
      name = "json-rpc-1.12.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/e6/3b/0c47157e2696e465a8f3fcf16ef660e5832040fd4fca165c49a317525cac/json-rpc-1.12.1.tar.gz";
        sha256 = "bc84451268b48a576d3138744322a8ce673eccadf7424edf4d446b1ddb59e58c";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/pavlov99/json-rpc";
        license = licenses.mit;
        description = "JSON-RPC transport implementation";
      };
    };

    "kafka-python" = python.mkDerivation {
      name = "kafka-python-1.4.6";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/26/de/81a65219f7a3f3b2f53b693edec7fb1933f1d7b68b49c931d810d6317f5e/kafka-python-1.4.6.tar.gz";
        sha256 = "08f83d8e0af2e64d25f94314d4bef6785b34e3b0df0effe9eebf76b98de66eeb";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/dpkp/kafka-python";
        license = licenses.asl20;
        description = "Pure Python client for Apache Kafka";
      };
    };

    "mccabe" = python.mkDerivation {
      name = "mccabe-0.6.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/06/18/fa675aa501e11d6d6ca0ae73a101b2f3571a565e0f7d38e062eec18a91ee/mccabe-0.6.1.tar.gz";
        sha256 = "dd8d182285a0fe56bace7f45b5e7d1a6ebcbf524e8f3bd87eb0f125271b8831f";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/pycqa/mccabe";
        license = licenses.mit;
        description = "McCabe checker, plugin for flake8";
      };
    };

    "parso" = python.mkDerivation {
      name = "parso-0.5.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/21/40/615957db4d178b7504c87b1a5b85fa5945b0b4fa5f5a845e31fc7aad6018/parso-0.5.1.tar.gz";
        sha256 = "666b0ee4a7a1220f65d367617f2cd3ffddff3e205f3f16a0284df30e774c2a9c";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/davidhalter/parso";
        license = licenses.mit;
        description = "A Python Parser";
      };
    };

    "pycodestyle" = python.mkDerivation {
      name = "pycodestyle-2.5.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/1c/d1/41294da5915f4cae7f4b388cea6c2cd0d6cd53039788635f6875dfe8c72f/pycodestyle-2.5.0.tar.gz";
        sha256 = "e40a936c9a450ad81df37f549d676d127b1b66000a6c500caa2b085bc0ca976c";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://pycodestyle.readthedocs.io/";
        license = licenses.mit;
        description = "Python style guide checker";
      };
    };

    "pyflakes" = python.mkDerivation {
      name = "pyflakes-2.1.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/52/64/87303747635c2988fcaef18af54bfdec925b6ea3b80bcd28aaca5ba41c9e/pyflakes-2.1.1.tar.gz";
        sha256 = "d976835886f8c5b31d47970ed689944a0262b5f3afa00a5a7b4dc81e5449f8a2";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/PyCQA/pyflakes";
        license = licenses.mit;
        description = "passive checker of Python programs";
      };
    };

    "pytest-runner" = python.mkDerivation {
      name = "pytest-runner-5.1";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/d9/6d/4b41a74b31720e25abd4799be72d54811da4b4d0233e38b75864dcc1f7ad/pytest-runner-5.1.tar.gz";
        sha256 = "25a013c8d84f0ca60bb01bd11913a3bcab420f601f0f236de4423074af656e7a";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [
        self."setuptools-scm"
      ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/pytest-dev/pytest-runner/";
        license = "UNKNOWN";
        description = "Invoke py.test as distutils command with dependency resolution";
      };
    };

    "pytoml" = python.mkDerivation {
      name = "pytoml-0.1.21";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/f4/ba/98ee2054a2d7b8bebd367d442e089489250b6dc2aee558b000e961467212/pytoml-0.1.21.tar.gz";
        sha256 = "8eecf7c8d0adcff3b375b09fe403407aa9b645c499e5ab8cac670ac4a35f61e7";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/avakar/pytoml";
        license = licenses.mit;
        description = "A parser for TOML-0.4.0";
      };
    };

    "pyyaml" = python.mkDerivation {
      name = "pyyaml-5.1.2";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/e3/e8/b3212641ee2718d556df0f23f78de8303f068fe29cdaa7a91018849582fe/PyYAML-5.1.2.tar.gz";
        sha256 = "01adf0b6c6f61bd11af6e10ca52b7d4057dd0be0343eb9283c878cf3af56aee4";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/yaml/pyyaml";
        license = licenses.mit;
        description = "YAML parser and emitter for Python";
      };
    };

    "requests" = python.mkDerivation {
      name = "requests-2.22.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/01/62/ddcf76d1d19885e8579acb1b1df26a852b03472c0e46d2b959a714c90608/requests-2.22.0.tar.gz";
        sha256 = "11e007a8a2aa0323f5a921e9e6a2d7e4e67d9877e85773fba9ba6419025cbeb4";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."certifi"
        self."chardet"
        self."idna"
        self."urllib3"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "http://python-requests.org";
        license = licenses.asl20;
        description = "Python HTTP for Humans.";
      };
    };

    "rxpy" = python.mkDerivation {
      name = "rxpy-0.1.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/64/ad/ad450332cc3541b50dc41734767610149fb39678d94a17264fca13dc8577/RXPY-0.1.0.tar.gz";
        sha256 = "c26978f66219140844f2c2eb1c1b689bc40fa78da354fe42c160141ed68eb3a4";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "http://www.acooke.org/rxpy/";
        license = "UNKNOWN";
        description = "A Regular Expression Library for Python";
      };
    };

    "service-factory" = python.mkDerivation {
      name = "service-factory-0.1.5";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/d1/32/bacd539bc748af613082f8cf80c82311373a05bb4af2d43bc2ff5bbdcdcc/service_factory-0.1.5.tar.gz";
        sha256 = "3f23f6e1a59eb2657eff48be5ee42e4cbd8f90eb3d134eab0017e13c54f6e3f7";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/proofit404/service-factory";
        license = "GPL3";
        description = "JSON RPC service factory for Python.";
      };
    };

    "setuptools-scm" = python.mkDerivation {
      name = "setuptools-scm-3.3.3";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/83/44/53cad68ce686585d12222e6769682c4bdb9686808d2739671f9175e2938b/setuptools_scm-3.3.3.tar.gz";
        sha256 = "bd25e1fb5e4d603dcf490f1fde40fb4c595b357795674c3e5cb7f6217ab39ea5";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/pypa/setuptools_scm/";
        license = licenses.mit;
        description = "the blessed package to manage your versions by scm tags";
      };
    };

    "uritools" = python.mkDerivation {
      name = "uritools-2.2.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/ab/1c/e9aa4a907806743298171510042447adc20cd5cf5b95436206a067e14496/uritools-2.2.0.tar.gz";
        sha256 = "80e8e23cafad54fd85811b5d9ba0fc595d933f5727c61c3937945eec09f99e2b";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/tkem/uritools/";
        license = licenses.mit;
        description = "RFC 3986 compliant, Unicode-aware, scheme-agnostic replacement for urlparse";
      };
    };

    "urlextract" = python.mkDerivation {
      name = "urlextract-0.13.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/5b/4b/ff87b5c2458f6c75ccc5a574f49ca117bd7f9bf057a09e1442d8ce165766/urlextract-0.13.0.tar.gz";
        sha256 = "3b3c013161fa13def54b4f05d3c3c26637624973e8e12ce5b1a6480fd305bde3";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."appdirs"
        self."idna"
        self."uritools"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/lipoja/URLExtract";
        license = licenses.mit;
        description = "Collects and extracts URLs from given text.";
      };
    };

    "urllib3" = python.mkDerivation {
      name = "urllib3-1.25.5";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/3c/31/aa26375d7028397ffa46765f91f5ccb087d37a99437b78259eb46f275f5b/urllib3-1.25.5.tar.gz";
        sha256 = "2f3eadfea5d92bc7899e75b5968410b749a054b492d5a6379c1344a1481bc2cb";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."certifi"
        self."idna"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://urllib3.readthedocs.io/";
        license = licenses.mit;
        description = "HTTP library with thread-safe connection pooling, file post, and more.";
      };
    };

    "yapf" = python.mkDerivation {
      name = "yapf-0.28.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/89/41/7f7c884531730c0cb471764e1ddf50f59d25bb2ab258ede633264344e9cb/yapf-0.28.0.tar.gz";
        sha256 = "6f94b6a176a7c114cfa6bad86d40f259bbe0f10cf2fa7f2f4b3596fc5802a41b";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "UNKNOWN";
        license = licenses.asl20;
        description = "A formatter for Python code.";
      };
    };
  };
  localOverridesFile = ./requirements_override.nix;
  localOverrides = import localOverridesFile { inherit pkgs python; };
  commonOverrides = [
    
  ];
  paramOverrides = [
    (overrides { inherit pkgs python; })
  ];
  allOverrides =
    (if (builtins.pathExists localOverridesFile)
     then [localOverrides] else [] ) ++ commonOverrides ++ paramOverrides;

in python.withPackages
   (fix' (pkgs.lib.fold
            extends
            generated
            allOverrides
         )
   )