<h1 id="post-title">Leaving Neocities</h1>

<span>Date: <time id="post-date">2021-01-11</time> </span>

<p id="post-excerpt">
I'll be moving the soupault website from Neocities to another platform.
The new site will be available as <a href="https://soupault.app">www.soupault.app</a>.
The process should be more or less seamless, and should not affect any functionality.
If you are interested in my motivation, read on. If you are wondering if I came to hate Neocities,
then no, by no means—it's not a bad platform, and I'm not advocating against it.
It's my choice and it should not influence yours.
</p>

I'd like to reiterate: this isn't a rage quit, and this post isn't a "don't use Neocities" statement.
Neocities isn't bad. I just don't feel that it's the best platform for this site now.

First, one reason I went for Neocities was to connect with the community of Web 1.0 revivalists.
Those are the people who cannot use classic "<abbr title="front matter, markdown, templates">FMT</abbr>"
static site generators like Jekyll or Hugo because they can only treat pages with a unique design
as a static assets.

Soupault is a tool that can remove the creativity vs automation dilemma,
since it can parse and manipulate complete pages and work as an HTML post-processor.
It allows the user to do as little or as much automation as they want.
I thought I can help them, but it seems like they don't want that help to begin with—some of them
seem to be against any kind of automation, even when there's no creativity vs automation dilemma anymore.

In fact, people seem to like soupault for the options to take both creativity and automation
to a new height. It allows you to use any other tools of your choice in the build process,
and I've seen people use it in ways I didn't think were possible.

Well, if there's ever a demand for a tool that can bring a little automation to a hand-made site workflow,
soupault will always offer it; but if there's no demand from that community now, I don't really need
to make it look appealing to them.

If I'm completely free to choose a hosting platform, what should I choose?
There are quite a few things I do like about the Neocities project. It's completely independent, which is a big deal
in a world dominated by "the big Internet" companies. It encourages people to make independent websites
and emphasizes creativity and fun. However, it also seems like there are lots of missed opportunities.

It could offer hosted websited to the its API to create [serverless visitor counters](https://github.com/neocities/neocities/issues/319)
and it should only take a simple configuration change, but they don't seem to care.
Judging by issue response and PR merge times, it looks like there's still only one maintainer, too.

If it were to make a next-generation hosting platorm for hobbyists, there are many things that could be done.
Someone should do it! There can be an option to enable seamless page versioning, using git or mercurial behind the scenes,
so that casual users can revert pages to previous versions and update them without fear.
There could be built-in privacy-respecting analytics.

I believe there can and should be a hosting platform that can serve as an antidote to website constructors.
However, at this point, Neocities isn't that, and it's not moving in that direction.
Maybe some day it will, or something else will appear.

Until then, I can use some other platform. Soupault has a ready to use build setup for Netlify, so I can use that
(in fact, you can deploy a soupault site on Netlify in [one click](https://app.netlify.com/start/deploy?repository=https://github.com/dmbaturin/soupault-sample-blog)).
One thing I like about their hosted CI is that you can just write a shell script for your build procedure,
rather than painstakingly embed shell commands in a YAML file.
Since soupault is available as a static executable, it's usable it with any CI service though:
I have written [tips](/tips-and-tricks/deployment/) for Netlify and GitHub Actions, but I could as well use any service
that allows downloading files as a part of the build process.

Of course, there's one more step required to migrate away from Neocities. Since I've been using soupault.neocities.org third-level domain,
I'm slightly locked in. I've registered [soupault.app](https://soupault.app) domain and that will be the new address.
Right now it will point to Neocities, using the custom domain mechanism. Meanwhile I'll update the project URL inside the source code
and on websites where applicable, then switch over to a new platform and replace the soupault.neocities.org site with a 301 redirect page.

I wish Neocities maintainers all the best, and personally I'll sure be checking websites of people who host them on Neocities.

