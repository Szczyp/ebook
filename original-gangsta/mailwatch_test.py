import mailwatch
import pickle

def test_extract_links():
    with open('test_mails', 'rb') as f:
        mails = pickle.load(f)
        assert list(mailwatch.extract_links(mails)) == [
            {'url': 'https://platypus1917.org/2019/07/02/althussers-marxism/',
             'from': 'qb@szczyp.com'},
            {'url': 'https://intransigence.org/2018/10/22/a-social-history-of-the-internet/',
             'from': 'qb@szczyp.com'}
        ]
