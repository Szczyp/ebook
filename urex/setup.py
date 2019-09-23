from setuptools import setup

setup(name='urex',
      version='1.0.0',
      description='url extractor',
      url='http://github.com/Szczyp/ebook',
      author='Szczyp',
      author_email='qb@szczyp.com',
      license='GPL3',
      packages=['urex'],
      entry_points={"console_scripts": ["urex = urex:main"]},
      include_package_data=True,
      zip_safe=False)
