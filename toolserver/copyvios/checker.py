# -*- coding: utf-8  -*-

from datetime import datetime
from hashlib import sha256
from time import time

from earwigbot import exceptions

from ..misc import open_sql_connection

def get_results(bot, site, query):
    page = site.get_page(query.title)
    try:
        page.get()  # Make sure that the page exists before we check it!
    except (exceptions.PageNotFoundError, exceptions.InvalidPageError):
        return page, None

    # if query.url:
    #     result = _get_url_specific_results(page, query.url)
    # else:
    #     conn = open_sql_connection(bot, "copyvioCache")
    #     if not query.nocache:
    #         result = _get_cached_results(page, conn)
    #     if query.nocache or not result:
    #         result = _get_fresh_results(page, conn)
    tstart = time()
    from earwigbot.wiki.copyvios import MarkovChain, MarkovChainIntersection, CopyvioCheckResult
    mc1 = MarkovChain(page.get())
    mc2 = MarkovChain(u"This is some random textual content for a page.")
    mci = MarkovChainIntersection(mc1, mc2)
    result = CopyvioCheckResult(True, 0.67123, "http://example.com/", 7, mc1, (mc2, mci))
    result.cached = False
    result.time = time() - tstart
    # END TEST BLOCK
    return page, result

def _get_url_specific_results(page, url):
    result = page.copyvio_compare(url)
    result.cached = False
    return result

def _get_cached_results(page, conn):
    query1 = "DELETE FROM cache WHERE cache_time < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 3 DAY)"
    query2 = "SELECT cache_url, cache_time, cache_queries, cache_process_time FROM cache WHERE cache_id = ? AND cache_hash = ?"
    pageid = page.pageid()
    hash = sha256(page.get()).hexdigest()

    with conn.cursor() as cursor:
        cursor.execute(query1)
        cursor.execute(query2, (pageid, hash))
        results = cursor.fetchall()
        if not results:
            return None

    url, cache_time, num_queries, original_time = results[0]
    result = page.copyvio_compare(url)
    result.cached = True
    result.queries = num_queries
    result.original_time = original_time
    result.cache_time = cache_time.strftime("%b %d, %Y %H:%M:%S UTC")
    result.cache_age = _format_date(cache_time)
    return result

def _format_date(cache_time):
    diff = datetime.utcnow() - cache_time
    if diff.seconds > 3600:
        return "{0} hours".format(diff.seconds / 3600)
    if diff.seconds > 60:
        return "{0} minutes".format(diff.seconds / 60)
    return "{0} seconds".format(diff.seconds)

def _get_fresh_results(page, conn):
    result = page.copyvio_check(max_queries=10, max_time=45)
    result.cached = False
    _cache_result(page, result, conn)
    return result

def _cache_result(page, result, conn):
    pageid = page.pageid()
    hash = sha256(page.get()).hexdigest()
    query1 = "SELECT 1 FROM cache WHERE cache_id = ?"
    query2 = "DELETE FROM cache WHERE cache_id = ?"
    query3 = "INSERT INTO cache VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?)"
    with conn.cursor() as cursor:
        cursor.execute(query1, (pageid,))
        if cursor.fetchall():
            cursor.execute(query2, (pageid,))
        cursor.execute(query3, (pageid, hash, result.url, result.queries,
                                result.time))
