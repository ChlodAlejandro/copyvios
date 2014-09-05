<%!
    from flask import g, request
    from copyvios.checker import T_POSSIBLE, T_SUSPECT
%>\
<%include file="/support/header.mako" args="title='Earwig\'s Copyvio Detector'"/>
<%namespace module="copyvios.highlighter" import="highlight_delta"/>\
<%namespace module="copyvios.misc" import="httpsfix, urlstrip"/>\
% if query.submitted:
    % if query.error == "bad action":
        <div id="info-box" class="red-box">
            <p>Unknown action: <b><span class="mono">${query.action | h}</span></b>.</p>
        </div>
    % elif query.error == "no search method":
        <div id="info-box" class="red-box">
            <p>No copyvio search methods were selected. A check can only be made using a search engine, links present in the page, or both.</p>
        </div>
    % elif query.error == "no URL":
        <div id="info-box" class="red-box">
            <p>URL comparison mode requires a URL to be entered. Enter one in the text box below, or choose copyvio search mode to look for content similar to the article elsewhere on the web.</p>
        </div>
    % elif query.error == "bad URI":
        <div id="info-box" class="red-box">
            <p>Unsupported URI scheme: <a href="${query.url | h}">${query.url | h}</a>.</p>
        </div>
    % elif query.error == "no data":
        <div id="info-box" class="red-box">
            <p>Couldn't find any text in <a href="${query.url | h}">${query.url | h}</a>. <i>Note:</i> only HTML and plain text pages are supported, and content generated by JavaScript or found inside iframes is ignored.</p>
        </div>
    % elif query.error == "timeout":
        <div id="info-box" class="red-box">
            <p>The URL <a href="${query.url | h}">${query.url | h}</a> timed out before any data could be retrieved.</p>
        </div>
    % elif not query.site:
        <div id="info-box" class="red-box">
            <p>The given site (project=<b><span class="mono">${query.project | h}</span></b>, language=<b><span class="mono">${query.lang | h}</span></b>) doesn't seem to exist. It may also be closed or private. <a href="//${query.lang | h}.${query.project | h}.org/">Confirm its URL.</a></p>
        </div>
    % elif query.title and not result:
        <div id="info-box" class="red-box">
            <p>The given page doesn't seem to exist: <a href="${query.page.url}">${query.page.title | h}</a>.</p>
        </div>
    % elif query.oldid and not result:
        <div id="info-box" class="red-box">
            <p>The given revision ID doesn't seem to exist: <a href="//${query.site.domain | h}/w/index.php?oldid=${query.oldid | h}">${query.oldid | h}</a>.</p>
        </div>
    % endif
%endif
<p>This tool attempts to detect <a href="//en.wikipedia.org/wiki/WP:COPYVIO">copyright violations</a> in articles. In search mode, it will check for similar content elsewhere on the web using <a href="//developer.yahoo.com/boss/search/">Yahoo! BOSS</a> and/or external links present in the text of the page, depending on which options are selected. In comparison mode, the tool will skip the searching step and display a report comparing the article to the given webpage, like the <a href="//tools.wmflabs.org/dupdet/">Duplication Detector</a>.</p>
<p>Running a full check can take up to 45 seconds if other websites are slow. Please be patient. If you get a timeout, wait a moment and refresh the page.</p>
<p>Specific websites can be skipped (for example, if their content is in the public domain) by being added to the <a href="//en.wikipedia.org/wiki/User:EarwigBot/Copyvios/Exclusions">excluded URL list</a>.</p>
<form id="cv-form" action="${request.script_root}" method="get">
    <table id="cv-form-outer">
        <tr>
            <td>Site:</td>
            <td colspan="3">
                <span class="mono">https://</span>
                <select name="lang">
                    <% selected_lang = query.orig_lang if query.orig_lang else g.cookies["CopyviosDefaultLang"].value if "CopyviosDefaultLang" in g.cookies else g.bot.wiki.get_site().lang %>\
                    % for code, name in query.all_langs:
                        % if code == selected_lang:
                            <option value="${code | h}" selected="selected">${name}</option>
                        % else:
                            <option value="${code | h}">${name}</option>
                        % endif
                    % endfor
                </select>
                <span class="mono">.</span>
                <select name="project">
                    <% selected_project = query.project if query.project else g.cookies["CopyviosDefaultProject"].value if "CopyviosDefaultProject" in g.cookies else g.bot.wiki.get_site().project %>\
                    % for code, name in query.all_projects:
                        % if code == selected_project:
                            <option value="${code | h}" selected="selected">${name}</option>
                        % else:
                            <option value="${code | h}">${name}</option>
                        % endif
                    % endfor
                </select>
                <span class="mono">.org</span>
            </td>
        </tr>
        <tr>
            <td id="cv-col1">Page&nbsp;title:</td>
            <td id="cv-col2">
                % if query.title:
                    <input class="cv-text" type="text" name="title" value="${query.page.title if query.page else query.title | h}" />
                % else:
                    <input class="cv-text" type="text" name="title" />
                % endif
            </td>
            <td id="cv-col3">or&nbsp;revision&nbsp;ID:</td>
            <td id="cv-col4">
                % if query.oldid:
                    <input class="cv-text" type="text" name="oldid" value="${query.oldid | h}" />
                % else:
                    <input class="cv-text" type="text" name="oldid" />
                % endif
            </td>
        </tr>
        <tr>
            <td>Action:</td>
            <td colspan="3">
                <table id="cv-form-inner">
                    <tr>
                        <td id="cv-inner-col1">
                            <input id="action-search" type="radio" name="action" value="search" ${'checked="checked"' if (query.action == "search" or not query.action) else ""} />
                        </td>
                        <td id="cv-inner-col2"><label for="action-search">Copyvio&nbsp;search:</label></td>
                        <td id="cv-inner-col3">
                            <input class="cv-search" type="hidden" name="use_engine" value="0" />
                            <input id="cv-cb-engine" class="cv-search" type="checkbox" name="use_engine" value="1" ${'checked="checked"' if (query.use_engine != "0") else ""} />
                            <label for="cv-cb-engine">Use&nbsp;search&nbsp;engine</label>
                            <input class="cv-search" type="hidden" name="use_links" value="0" />
                            <input id="cv-cb-links" class="cv-search" type="checkbox" name="use_links" value="1" ${'checked="checked"' if (query.use_links != "0") else ""} />
                            <label for="cv-cb-links">Use&nbsp;links&nbsp;in&nbsp;page</label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <input id="action-compare" type="radio" name="action" value="compare" ${'checked="checked"' if query.action == "compare" else ""} />
                        </td>
                        <td><label for="action-compare">URL&nbsp;comparison:</label></td>
                        <td>
                            <input class="cv-compare cv-text" type="text" name="url"
                            % if query.url:
                                value="${query.url | h}"
                            % endif
                            />
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        % if query.nocache or (result and result.cached):
            <tr>
                <td><label for="cb-nocache">Bypass&nbsp;cache:</label></td>
                <td colspan="3">
                    <input id="cb-nocache" type="checkbox" name="nocache" value="1" ${'checked="checked"' if query.nocache else ""}  />
                </td>
            </tr>
        % endif
        <tr>
            <td colspan="4">
                <button type="submit">Submit</button>
            </td>
        </tr>
    </table>
</form>
% if result:
    <% hide_comparison = "CopyviosHideComparison" in g.cookies and g.cookies["CopyviosHideComparison"].value == "True" %>
    <div id="cv-result" class="${'red' if result.confidence >= T_SUSPECT else 'yellow' if result.confidence >= T_POSSIBLE else 'green'}-box">
        <h2 id="cv-result-header">
            % if result.confidence >= T_POSSIBLE:
                <a href="${query.page.url}">${query.page.title | h}</a>
                % if query.oldid:
                    @<a href="//${query.site.domain | h}/w/index.php?oldid=${query.oldid | h}">${query.oldid | h}</a>
                % endif
                is a ${"suspected" if result.confidence >= T_SUSPECT else "possible"} violation of <a href="${result.url | h}">${result.url | urlstrip, h}</a>.
            % else:
                % if query.oldid:
                    No violations detected in <a href="${query.page.url}">${query.page.title | h}</a> @<a href="//${query.site.domain | h}/w/index.php?oldid=${query.oldid | h}">${query.oldid | h}</a>.
                % else:
                    No violations detected in <a href="${query.page.url}">${query.page.title | h}</a>.
                % endif
            % endif
        </h2>
    </div>
    <% skips = False %>
    % if query.action == "search":
        <table id="cv-result-sources">
            <tr>
                <th>URL</th>
                <th>Confidence</th>
            </tr>
            % for source in result.sources:
                <tr>
                    <td><a href="${source.url | h}">${source.url | h}</a> (<a class="source-compare" href="${request.url | httpsfix, h}&amp;action=compare&amp;url=${source.url | u}">compare</a>)</td>
                    % if source.skipped:
                        <% skips = True %>
                        <td><span class="source-skipped">Skipped</span></td>
                    % else:
                        <td><span class="source-confidence ${"source-suspect" if source.confidence >= T_SUSPECT else "source-possible" if source.confidence >= T_POSSIBLE else "source-novio"}">${round(source.confidence * 100, 1)}%</span></td>
                    % endif
                </tr>
            % endfor
        </table>
    % endif
    <ul id="cv-result-list">
        % if query.action == "compare":
            <li><b><span class="mono">${round(result.confidence * 100, 1)}%</span></b> confidence of a violation.</li>
        % endif
        % if query.redirected_from:
            <li>Redirected from <a href="${query.redirected_from.url}">${query.redirected_from.title | h}</a>. <a href="${request.url | httpsfix, h}&amp;noredirect=1">Check the original page.</a></li>
        % endif
        % if skips:
            <li>Since a suspected source was found with a high confidence value, some URLs were skipped. <a href="javascript:alert('Not implemented yet!');">Check all URLs.</a></li>
        % endif
        % if result.cached:
            <li>Results are <a id="cv-cached" href="#">cached<span>To save time (and money), this tool will retain the results of checks for up to 72 hours. This includes the URLs of the checked sources, but neither their content nor the content of the article. Future checks on the same page (assuming it remains unchanged) will not involve additional search queries, but a fresh comparison against the source URL will be made. If the page is modified, a new check will be run.</span></a> from <abbr title="${result.cache_time}">${result.cache_age} ago</abbr>. Originally generated in <span class="mono">${round(result.time, 3)}</span> seconds using <span class="mono">${result.queries}</span> queries. <a href="${request.url | httpsfix, h}&amp;nocache=1">Bypass the cache.</a></li>
        % elif query.action == "compare":
            <li>Results generated in <span class="mono">${round(result.time, 3)}</span> seconds.</li>
        % else:
            <li>Results generated in <span class="mono">${round(result.time, 3)}</span> seconds using <span class="mono">${result.queries}</span> queries.</li>
        % endif
        <li><a id="cv-chain-link" href="#cv-chain-table" onclick="copyvio_toggle_details()">${"Show" if hide_comparison else "Hide"} comparison:</a></li>
    </ul>
    <table id="cv-chain-table" style="display: ${'none' if hide_comparison else 'table'};">
        <tr>
            <td class="cv-chain-cell">Article: <div class="cv-chain-detail"><p>${highlight_delta(result.article_chain, result.best.chains[1] if result.best else None)}</p></div></td>
            <td class="cv-chain-cell">Source: <div class="cv-chain-detail"><p>${highlight_delta(result.best.chains[0], result.best.chains[1]) if result.best else ""}</p></div></td>
        </tr>
    </table>
% endif
<%include file="/support/footer.mako"/>
