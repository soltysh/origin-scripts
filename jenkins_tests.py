import re
from datetime import datetime

from scrapy import Request, Item, Field
from scrapy.spiders import XMLFeedSpider

PR_RE = re.compile(r'https://github.com/openshift/origin/pull/\d+', re.M)

class Flake(Item):
    """
    Flake item class.
    """
    date = Field()
    link = Field()
    pr = Field()
    output = Field()


class JenkinsTestsSpider(XMLFeedSpider):
    """
    Main spider class, inheriting from XMLFeedSpider.
    """
    name = 'jenkins_tests'
    # we only crawl this particular domain
    allowed_domains = ['ci.openshift.redhat.com']
    # the namespace of the rssAll and rssFailed
    namespaces = [('x', 'http://www.w3.org/2005/Atom'),]
    # only xml iterator works
    iterator = 'xml'
    # which tags to process
    itertag = 'x:entry'

    def __init__(self, pattern='', url='', since=None, offset=256, *args, **kwargs):
        """
        Initiate the spider saving arguments from user (-a name=value)
        """
        super(JenkinsTestsSpider, self).__init__(*args, **kwargs)
        if len(pattern) == 0 or len(url) == 0:
            raise Exception('missing -a pattern or -a url argument')
        self.pattern = re.compile(pattern, re.I)
        self.start_urls = [url]
        if since:
            # if parsing error occurs it'll throw an exception
            self.since = datetime.strptime(since, '%Y-%m-%dT%H:%M:%SZ')
        self.offset = offset

    def parse_node(self, response, node):
        """
        Method responsible for parsing rssAll/rssFailed entries from jenkins.
        """
        url = node.xpath('x:link/@href').extract_first()
        date = node.xpath('x:updated/text()').extract_first()
        # filter dates, if since was specified
        if self.since and datetime.strptime(date, '%Y-%m-%dT%H:%M:%SZ') < self.since:
            return
        # create a request object that will be further processed using parse_output
        request = Request(url=url + 'logText/progressiveText?start=0',
            callback=self.parse_output)
        # save the original URL and date of a test run
        request.meta['url'] = url
        request.meta['date'] = date
        # and trigger processing
        yield request

    def parse_output(self, response):
        """
        Method responsible for parsing the output from a test run.
        """
        output = str(response.body)
        flake = Flake(pr=' - none - ')
        # read PR number from output, since sometimes comment lacks that information
        pr_match = PR_RE.search(output)
        if pr_match:
            flake['pr'] = pr_match.group()
        flake['date'] = response.meta['date']
        flake['link'] = response.meta['url']
        # search for the pattern in the output
        match = self.pattern.search(output)
        if match:
            # save only those items that match the pattern, with offset characters
            # before and after the pattern
            flake['output'] = output[match.start()-self.offset:match.end()+self.offset]
            yield flake
