import re

from scrapy import Request, Item, Field
from scrapy.spiders import XMLFeedSpider

PR_RE = re.compile(r'https://github.com/openshift/origin/pull/\d+', re.M)

class Flake(Item):
    link = Field()
    pr = Field()

class JenkinsTestsSpider(XMLFeedSpider):
    name = 'jenkins_tests'
    allowed_domains = ['redhat.com']
    namespaces = [
        ('x', 'http://www.w3.org/2005/Atom'),
    ]
    iterator = 'xml'
    itertag = 'x:entry'

    def __init__(self, pattern='', url='', *args, **kwargs):
        super(JenkinsTestsSpider, self).__init__(*args, **kwargs)
        if len(pattern) == 0 or len(url) == 0:
            raise Exception('missing -a pattern or -a url argument')
        self.pattern = pattern
        self.start_urls = [url]

    def parse_node(self, response, node):
        url = node.xpath('x:link/@href').extract_first()
        request = Request(url=url + 'logText/progressiveText?start=0',
            callback=self.parse_output)
        request.meta['url'] = url
        yield request

    def parse_output(self, response):
        output = str(response.body)
        flake = Flake(pr='-missing-')
        pr_match = PR_RE.search(output)
        if pr_match:
            flake['pr'] = pr_match.group()
        flake['link'] = response.meta['url']
        # TODO: add date
        # TODO: add output before and after the pattern
        if self.pattern in output:
            yield flake
