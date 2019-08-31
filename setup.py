from setuptools import setup

setup(name='ebook',
      version='1.0.3',
      description='Make ebooks from links',
      url='http://github.com/Szczyp/ebook',
      author='Szczyp',
      author_email='qb@szczyp.com',
      license='GPL3',
      packages=['ebook'],
      entry_points={"console_scripts": ["ebook = ebook.ebook:main",
                                        "url2ebook = ebook.ebook:url2ebook",
                                        "hyphenate = ebook.hyphenate:main",
                                        "convert_img = ebook.convert_img:main"]},
      include_package_data=True,
      zip_safe=False)
