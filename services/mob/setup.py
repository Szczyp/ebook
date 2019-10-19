from setuptools import setup

setup(name='mob',
      version='1.0.0',
      description='run kindlegen on epub',
      url='http://github.com/Szczyp/ebook',
      author='Szczyp',
      author_email='qb@szczyp.com',
      license='GPL3',
      packages=['mob'],
      entry_points={"console_scripts": ["mob = mob:main"]},
      include_package_data=True,
      zip_safe=False)
