import re
from datetime import datetime

from scrapy import Request, Item, Field
from scrapy.spiders import XMLFeedSpider

PR_RE = re.compile(r'https://github.com/openshift/origin/pull/\d+', re.M)

class Flake(Item):
    date = Field()
    link = Field()
    pr = Field()
    output = Field()


class JenkinsTestsSpider(XMLFeedSpider):
    name = 'jenkins_tests'
    allowed_domains = ['redhat.com']
    namespaces = [('x', 'http://www.w3.org/2005/Atom'),]
    iterator = 'xml'
    itertag = 'x:entry'

    def __init__(self, pattern='', url='', since=None, *args, **kwargs):
        super(JenkinsTestsSpider, self).__init__(*args, **kwargs)
        if len(pattern) == 0 or len(url) == 0:
            raise Exception('missing -a pattern or -a url argument')
        self.pattern = re.compile(pattern, re.I)
        self.start_urls = [url]
        if since:
            self.since = datetime.strptime(since, '%Y-%m-%dT%H:%M:%SZ')

    def parse_node(self, response, node):
        url = node.xpath('x:link/@href').extract_first()
        date = node.xpath('x:updated/text()').extract_first()
        if self.since and datetime.strptime(date, '%Y-%m-%dT%H:%M:%SZ') < self.since:
            return
        request = Request(url=url + 'logText/progressiveText?start=0', callback=self.parse_output)
        request.meta['url'] = url
        request.meta['date'] = date
        yield request

    def parse_output(self, response):
        output = str(response.body)
        flake = Flake(pr=' - none - ')
        pr_match = PR_RE.search(output)
        if pr_match:
            flake['pr'] = pr_match.group()
        flake['date'] = response.meta['date']
        flake['link'] = response.meta['url']
        pattern_match = self.pattern.search(output)
        if pattern_match:
            flake['output'] = output[pattern_match.start()-256:pattern_match.end()+256]
            yield flake
