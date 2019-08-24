from setuptools import setup

setup(name='ebook',
      version='1.0.2',
      description='Make ebooks from links',
      url='http://github.com/Szczyp/ebook',
      author='Szczyp',
      author_email='qb@szczyp.com',
      license='GPL3',
      packages=['ebook'],
      entry_points={"console_scripts": ["ebook = ebook.ebook:main",
                                        "hyphenate = ebook.hyphenate:main",
                                        "strip_img = ebook.strip_img:main"]},
      include_package_data=True,
      zip_safe=False)
