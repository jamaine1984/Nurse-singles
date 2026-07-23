param(
  [string]$BaseUrl = 'https://nurse-singles.com',
  [string]$LastMod = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'

function Encode-Html([string]$Value) {
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Write-Utf8File([string]$Path, [string]$Content) {
  $directory = Split-Path -Parent $Path
  if ($directory -and !(Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

$Posts = @(
  [ordered]@{
    Slug = 'us-nurse-singles-vs-tinder'
    Title = 'Nurse Singles vs. Tinder: A Free Dating App Built Around Healthcare Schedules'
    Region = 'United States'
    Category = 'Comparison'
    Image = 'us-healthcare-video-intros.jpg'
    Meta = 'Compare Nurse Singles with broad swipe apps for nurses who want free access, speed dating, Nurse Hub guides, games, a break room, and shift-aware matching.'
    Intro = 'Tinder can be useful for meeting a wide range of people, but nurses often need more than a swipe feed. Twelve-hour shifts, rotating weekends, sleep recovery, and workplace privacy change the dating problem.'
    Compare = 'Nurse Singles is built as a healthcare-first alternative: free to start, focused on nurses and healthcare workers, and designed around faster introductions instead of endless swiping. The goal is not to copy a broad dating app; it is to make the first conversation more relevant for people who work around patients, shifts, and call schedules.'
    Features = @('Speed dating rooms help nurses meet faster without swiping all day.', 'The Nurse Hub adds dating guides, healthcare lifestyle topics, and community content.', 'Games and the Break Room create low-pressure ways to interact before a full date.', 'Profiles can highlight shift type, role, and dating goals without exposing exact workplace details.')
    Night = 'Schedule-aware dating resources can support the wider overnight-worker audience, while Nurse Singles stays focused on healthcare singles.'
    CTA = 'For nurses who want a free healthcare-focused place to start, Nurse Singles gives the conversation more context before anyone plans a date.'
  }
  [ordered]@{
    Slug = 'us-nurse-singles-vs-bumble'
    Title = 'Nurse Singles vs. Bumble: Why Healthcare Singles Need More Than a Generic Match'
    Region = 'United States'
    Category = 'Comparison'
    Image = 'us-allied-healthcare-dating.jpg'
    Meta = 'A nurse-focused comparison of Nurse Singles and broad dating apps for healthcare workers who want free access, speed dating, and community features.'
    Intro = 'Bumble is a broad dating app with a large audience, but most healthcare workers still have to explain the same schedule problems over and over. Nurse Singles starts from the reality that clinical life affects dating.'
    Compare = 'Instead of making nurses translate their schedule into a generic profile, Nurse Singles can put shift type, healthcare role, safety expectations, and speed dating in the center of the experience. That makes it a better fit for nurses who want matches to understand work-life timing from the start.'
    Features = @('Free-to-start access lowers the barrier for nurses, students, and travel clinicians.', 'Speed dating gives busy users a faster way to test chemistry.', 'The Break Room supports casual conversation when users are not ready for a direct date.', 'Nurse Hub articles give search visitors useful answers before they sign up.')
    Night = 'For people outside healthcare who still date around overnight schedules, Schedule-aware dating content can carry that broader night-work message.'
    CTA = 'Use Nurse Singles when the main issue is healthcare compatibility, not just finding another profile in a general dating pool.'
  }
  [ordered]@{
    Slug = 'us-nurse-singles-vs-hinge'
    Title = 'Nurse Singles vs. Hinge: Serious Dating for Nurses Without Endless Schedule Explaining'
    Region = 'United States'
    Category = 'Comparison'
    Image = 'us-doctor-nurse-dating-boundaries.jpg'
    Meta = 'How Nurse Singles can serve healthcare singles who want serious dating, speed dating, free access, and a community built around nurse schedules.'
    Intro = 'Hinge positions itself for intentional dating, but it is still a broad app. Nurses who want something serious may still run into the same gap: most matches do not understand clinical schedules or post-shift recovery.'
    Compare = 'Nurse Singles can support serious dating with healthcare-specific context first. A profile can explain shift type, role, travel status, and communication style while speed dating helps people move past dead-end chats faster.'
    Features = @('Healthcare identity gives matches a more useful starting point.', 'Speed dating creates a quick yes-or-no path before long messaging threads.', 'Games and Break Room topics make conversation easier between shifts.', 'Privacy controls can reduce pressure to reveal hospital, department, or school details.')
    Night = 'Schedule-aware dating content can cross-promote the overnight schedule angle for singles who are not nurses but still live a night-work lifestyle.'
    CTA = 'Nurse Singles is the more focused choice when a nurse wants serious dating with people who respect healthcare timing.'
  }
  [ordered]@{
    Slug = 'us-free-nurse-dating-app'
    Title = 'Free Nurse Dating App: What Nurses Should Expect Before Signing Up'
    Region = 'United States'
    Category = 'Free dating'
    Image = 'us-night-shift-nurse-dating.jpg'
    Meta = 'A guide for nurses looking for a free dating app with healthcare-focused profiles, speed dating, privacy, games, and community features.'
    Intro = 'A free nurse dating app should do more than let people create profiles. It should help nurses meet around real schedules, keep workplace information private, and move from interest to conversation without wasting time.'
    Compare = 'Broad apps like Tinder, Bumble, and Hinge can be free to download or start, but they are not built specifically for healthcare workers. Nurse Singles can stand out by making the healthcare context the point, not an afterthought.'
    Features = @('Free-to-start signup for nurses and healthcare singles.', 'Speed dating for fast introductions when time is limited.', 'Nurse Hub articles that answer real healthcare dating questions.', 'Break Room and games for low-pressure interaction before a full match.')
    Night = 'Schedule-aware dating content can help capture people searching for overnight dating, while Nurse Singles speaks directly to nurses and clinical staff.'
    CTA = 'Start with a profile that explains your schedule, privacy preferences, and dating goals so the right people understand your life from the first message.'
  }
  [ordered]@{
    Slug = 'us-speed-dating-for-nurses'
    Title = 'Speed Dating for Nurses: Meet Faster Without Swiping All Day'
    Region = 'United States'
    Category = 'Speed dating'
    Image = 'us-healthcare-video-intros.jpg'
    Meta = 'Speed dating can help nurses meet faster around shift work, fatigue, short breaks, and busy healthcare schedules.'
    Intro = 'Nurses do not always have the time or energy to swipe through hundreds of profiles after a demanding shift. Speed dating gives the app a clearer purpose: meet briefly, check chemistry, and decide whether to continue.'
    Compare = 'Generic swipe apps often turn dating into a long sorting process. Nurse Singles can make introductions faster by pairing speed dating with healthcare-specific profile signals such as shift type, role, location, and dating goals.'
    Features = @('Short speed dating rooms reduce the need for long pre-chat.', 'Mutual interest after a room can open the next conversation.', 'Shift-aware timing helps users join when they are actually available.', 'Safety prompts can remind users not to share patient or workplace-sensitive details.')
    Night = 'Schedule-aware dating content can use the same schedule-aware message for overnight workers beyond healthcare.'
    CTA = 'For busy nurses, speed dating is a practical way to find real interest before investing a whole evening in messages.'
  }
  [ordered]@{
    Slug = 'us-nurse-break-room-dating-community'
    Title = 'The Nurse Singles Break Room: Dating Community Before the First Date'
    Region = 'United States'
    Category = 'Community'
    Image = 'us-allied-healthcare-dating.jpg'
    Meta = 'The Nurse Singles Break Room can help healthcare singles talk, relax, and connect before turning every interaction into a formal date.'
    Intro = 'A nurse dating app should not make every conversation feel like a job interview. The Break Room can give healthcare singles a place to talk, laugh, and discover personality before deciding whether there is romantic interest.'
    Compare = 'Tinder, Bumble, and Hinge focus on matches and messages. Nurse Singles can add a stronger community layer by giving users healthcare-friendly spaces that feel closer to real break-room conversation without exposing patient information.'
    Features = @('Casual discussion prompts for nurses, students, and healthcare workers.', 'Community topics that do not require instant flirting.', 'A path from Break Room conversation to speed dating or direct matching.', 'Clear reminders that patient stories and protected health information do not belong in the app.')
    Night = 'Schedule-aware dating content can share the schedule-aware theme, but the Nurse Singles Break Room should stay healthcare-specific.'
    CTA = 'A stronger community can help users return more often, build trust, and feel comfortable before they sign up or start dating.'
  }
  [ordered]@{
    Slug = 'us-nurse-hub-healthcare-singles'
    Title = 'Nurse Hub for Healthcare Singles: Guides That Make the App Worth Joining'
    Region = 'United States'
    Category = 'Nurse Hub'
    Image = 'us-healthcare-privacy-dating.jpg'
    Meta = 'Nurse Hub articles can bring search traffic from nurses looking for dating advice, privacy tips, speed dating, and healthcare community features.'
    Intro = 'Search traffic grows when pages answer real questions. Nurse Hub gives Nurse Singles a way to help nurses before they create an account, then point them toward speed dating, games, the Break Room, and free-to-start signup.'
    Compare = 'Broad dating apps usually rank for broad dating topics. Nurse Singles should own the specific questions: dating as a nurse, travel nurse dating, night shift dating, healthcare privacy, and whether nurse-focused apps are better than generic swipe apps.'
    Features = @('Comparison articles for Tinder, Bumble, and Hinge search intent.', 'Privacy guides for workplace boundaries and safe profiles.', 'Shift dating guides for night shift, travel nurses, and nursing students.', 'Internal links that move readers from advice to signup.')
    Night = 'Schedule-aware dating content can be referenced when a topic is about overnight work rather than healthcare identity alone.'
    CTA = 'Every useful Nurse Hub page should answer a search question and give a clear reason to open Nurse Singles.'
  }
  [ordered]@{
    Slug = 'us-healthcare-games-and-dating'
    Title = 'Healthcare Dating With Games: A More Relaxed Way for Nurses to Connect'
    Region = 'United States'
    Category = 'Games'
    Image = 'us-er-nurse-dating.jpg'
    Meta = 'Games can help nurses and healthcare singles start conversations before a formal match or first date.'
    Intro = 'Dating apps can feel repetitive when every chat starts the same way. Games give nurses a lighter way to interact, show personality, and build comfort before deciding whether to meet.'
    Compare = 'Generic swipe apps focus heavily on profile selection. Nurse Singles can create a different reason to stay: speed dating, games, Nurse Hub content, and a Break Room that gives users more than a swipe queue.'
    Features = @('Short games can turn downtime into low-pressure conversation.', 'Shared game results can become safer icebreakers.', 'Healthcare-themed prompts can connect users around shift life.', 'Games can support free engagement before a user chooses deeper features.')
    Night = 'Schedule-aware dating content can carry game-based icebreakers for overnight workers who want something lighter than standard matching.'
    CTA = 'Games should not replace real dating intent, but they can make the first step feel easier for tired healthcare workers.'
  }
  [ordered]@{
    Slug = 'us-night-shift-dating-nurse-singles'
    Title = 'Night-Shift Dating for Nurses: How Nurse Singles Helps With Schedule Compatibility'
    Region = 'United States'
    Category = 'Night shift'
    Image = 'us-night-shift-nurse-dating.jpg'
    Meta = 'A guide to using Nurse Singles for healthcare dating and schedule-aware dating content for the broader overnight worker audience.'
    Intro = 'Night shift dating is one of the clearest problems in healthcare relationships. Nurses may be awake when most people are asleep, tired when others want to go out, and free on weekdays instead of weekends.'
    Compare = 'Nurse Singles should own the healthcare side of that search. The app can explain availability, shift type, quiet hours, and realistic dating windows without making users repeat the same schedule story in every message.'
    Features = @('Nurse Singles targets nurses, nursing students, travel clinicians, and healthcare workers.', 'Night-shift dating content should explain sleep, timing, and recovery without treating healthcare schedules as a small detail.', 'Schedule-aware profile prompts can reduce mismatched expectations before a chat starts.', 'Healthcare privacy and role-based community should stay strongest on Nurse Singles.')
    Night = 'This page is focused on the healthcare side of night-shift dating: nurses can use Nurse Singles to show real availability, protect workplace privacy, and meet people who understand shift life.'
    CTA = 'Use Nurse Singles when healthcare identity, shift compatibility, and respectful timing matter most.'
  }
  [ordered]@{
    Slug = 'us-travel-nurses-speed-dating'
    Title = 'Travel Nurses and Speed Dating: Meeting People Before the Assignment Ends'
    Region = 'United States'
    Category = 'Travel nurses'
    Image = 'us-travel-nurse-dating.jpg'
    Meta = 'Travel nurses need faster dating tools because assignment windows are short and city plans can change.'
    Intro = 'Travel nurses may only have a few weeks in a city before the next assignment. A slow match-and-message process can waste the best part of that window.'
    Compare = 'Broad apps can show nearby singles, but they may not understand assignment timing. Nurse Singles can let travel nurses explain city, assignment window, shift type, and dating goals, then use speed dating to make introductions faster.'
    Features = @('Assignment-friendly profiles can show current city and optional next city.', 'Speed dating helps users check chemistry before a schedule changes.', 'Video intros can reduce wasted travel across town.', 'Privacy controls keep housing and facility details off the public profile.')
    Night = 'Schedule-aware dating content can support travel workers on overnight schedules, while Nurse Singles keeps the healthcare assignment details front and center.'
    CTA = 'For travel nurses, faster introductions and clear scheduling can make the difference between a real date and a missed opportunity.'
  }
  [ordered]@{
    Slug = 'international-nurse-singles-vs-swipe-apps'
    Title = 'Nurse Singles vs. Swipe Apps Worldwide: A Healthcare Dating Alternative'
    Region = 'International'
    Category = 'Comparison'
    Image = 'international-global-travel-nurse-dating.jpg'
    Meta = 'International healthcare workers can use Nurse Singles for a more focused alternative to broad swipe apps.'
    Intro = 'Tinder, Bumble, and Hinge are known in many countries, but nurses and healthcare workers still face the same problem: generic profiles rarely explain shifts, clinical stress, privacy, or cross-border work.'
    Compare = 'Nurse Singles can offer a more focused international path by centering healthcare identity, free-to-start access, speed dating, Nurse Hub guides, and community features that are useful before a paid upgrade or first date.'
    Features = @('International articles can target nurses by country, region, and schedule problem.', 'Speed dating helps users avoid long chats that do not fit time zones.', 'The Break Room can support healthcare conversation across borders.', 'Profiles can keep exact employer and credential details private.')
    Night = 'Schedule-aware dating content can help capture global overnight-shift searches that are not limited to healthcare.'
    CTA = 'Healthcare singles worldwide need more than a swipe queue; they need context, privacy, and faster ways to meet.'
  }
  [ordered]@{
    Slug = 'international-free-healthcare-dating-app'
    Title = 'Free Healthcare Dating App for International Nurses and Clinical Workers'
    Region = 'International'
    Category = 'Free dating'
    Image = 'international-europe-healthcare-workers-dating.jpg'
    Meta = 'A global guide for nurses and healthcare workers looking for a free-to-start dating app with community, speed dating, and privacy.'
    Intro = 'International healthcare workers often move between cities, countries, or contracts. A free-to-start healthcare dating app can make it easier to test the community before committing time.'
    Compare = 'Broad dating apps may have more total users, but Nurse Singles can be more relevant for people who want healthcare-aware matching, night-shift understanding, and community features built around clinical life.'
    Features = @('Free-to-start access for nurses, students, doctors, and allied health workers.', 'Country and region articles that answer local search intent.', 'Speed dating and video intros for long-distance or time-zone matches.', 'Privacy controls for workplace, department, and credential visibility.')
    Night = 'Schedule-aware dating content can support people whose biggest issue is overnight work rather than healthcare identity.'
    CTA = 'International growth should focus on useful local pages and clear reasons for healthcare singles to join.'
  }
  [ordered]@{
    Slug = 'international-speed-dating-for-healthcare-workers'
    Title = 'Speed Dating for Healthcare Workers Around the World'
    Region = 'International'
    Category = 'Speed dating'
    Image = 'international-canada-healthcare-singles.jpg'
    Meta = 'Speed dating can help nurses and healthcare workers meet faster across regions, time zones, and rotating schedules.'
    Intro = 'Healthcare workers around the world deal with time pressure. Whether someone works in Canada, the UK, Australia, the Philippines, India, Africa, Europe, or the Middle East, a faster introduction can be more useful than a long swipe process.'
    Compare = 'Nurse Singles can use speed dating as a clear difference from broad dating apps. Instead of waiting for a match that may never turn into conversation, users can join short rooms organized around timing, role, or interest.'
    Features = @('Short rooms make international introductions more practical.', 'Time-zone-aware timing can reduce missed conversations.', 'Mutual opt-in after a speed room keeps follow-up respectful.', 'Community topics can include travel nursing, study abroad, and healthcare expat life.')
    Night = 'Schedule-aware dating content can support speed dating for non-healthcare overnight workers in different countries.'
    CTA = 'Speed dating gives international healthcare singles a faster way to find real interest while respecting time zones and shifts.'
  }
  [ordered]@{
    Slug = 'international-night-shift-dating-healthcare'
    Title = 'International Night-Shift Dating for Nurses and Healthcare Workers'
    Region = 'International'
    Category = 'Night shift'
    Image = 'international-middle-east-healthcare-expats.jpg'
    Meta = 'Night shift dating is a global healthcare issue, from hospitals to clinics to travel assignments.'
    Intro = 'Night shift is not only a U.S. dating problem. Nurses, doctors, techs, and caregivers around the world need relationships that respect sleep, recovery, and unusual free time.'
    Compare = 'Nurse Singles can focus on the healthcare version of night-shift dating: long rotations, post-shift recovery, weekend work, travel assignments, and time-zone differences.'
    Features = @('Night-shift profile prompts help explain real availability.', 'Speed dating can be scheduled around late-night or post-shift windows.', 'Break Room topics can make late-hour community feel less isolated.', 'Privacy rules should still protect workplace details and patient information.')
    Night = 'This page keeps Nurse Singles focused on healthcare workers who need schedule-aware dating, not generic swipe behavior.'
    CTA = 'The best night shift dating content should speak to sleep, timing, patience, and realistic expectations.'
  }
  [ordered]@{
    Slug = 'international-nurse-break-room-community'
    Title = 'Nurse Break Room Community for International Healthcare Singles'
    Region = 'International'
    Category = 'Community'
    Image = 'international-africa-nurses-dating.jpg'
    Meta = 'The Nurse Singles Break Room can help international healthcare workers connect before dating.'
    Intro = 'International users may not want to jump straight into dating messages. A Break Room gives healthcare singles a place to talk about schedules, study, travel, and everyday life before deciding who they want to meet.'
    Compare = 'Swipe apps usually treat community as secondary. Nurse Singles can stand out by giving nurses and healthcare workers more reasons to return: articles, conversation spaces, games, and speed dating.'
    Features = @('Region-aware conversation topics for healthcare workers.', 'Low-pressure community before romantic follow-up.', 'Games and prompts that reduce awkward first messages.', 'Safety rules that keep patient stories and private workplace details out of public areas.')
    Night = 'Schedule-aware dating content can use a similar community idea for overnight workers outside healthcare.'
    CTA = 'Community can turn search visitors into returning users because the app offers value before the first date.'
  }
  [ordered]@{
    Slug = 'international-nurse-hub-guides'
    Title = 'International Nurse Hub Guides: Search Topics That Bring Healthcare Singles In'
    Region = 'International'
    Category = 'Nurse Hub'
    Image = 'international-global-travel-nurse-dating.jpg'
    Meta = 'International Nurse Hub guides can answer search questions for nurses, travel clinicians, students, and healthcare workers.'
    Intro = 'International SEO should not be random. The best Nurse Hub topics answer what healthcare singles actually search: nurse dating app, travel nurse dating, night shift dating, healthcare worker dating, privacy, and country-specific guides.'
    Compare = 'Broad dating sites can publish general dating advice. Nurse Singles should publish healthcare-specific pages with useful details and clear sign-up paths.'
    Features = @('Country pages for high-interest healthcare regions.', 'Comparison pages against broad apps without unsupported claims.', 'Guides for nursing students, travel workers, and healthcare expats.', 'Internal links to speed dating, Break Room, games, and schedule-aware dating content when relevant.')
    Night = 'Use schedule-aware dating links only when the article is about overnight schedules, not every healthcare topic.'
    CTA = 'A strong Nurse Hub can become the search engine front door for the dating app.'
  }
  [ordered]@{
    Slug = 'international-travel-nurse-dating-app'
    Title = 'International Travel Nurse Dating App: Dating Between Assignments and Countries'
    Region = 'International'
    Category = 'Travel nurses'
    Image = 'international-philippines-nurses-dating.jpg'
    Meta = 'Travel nurses and healthcare expats need dating features for assignments, time zones, privacy, and faster introductions.'
    Intro = 'International travel nurses may be away from home, working difficult shifts, and building a social life in a new country. Dating works better when the app understands temporary locations and schedule fatigue.'
    Compare = 'A broad swipe app can show people nearby, but it may not explain why assignment dates, shift type, and professional boundaries matter. Nurse Singles can make those details part of the profile and speed dating flow.'
    Features = @('Assignment city and travel openness can be optional profile signals.', 'Video intros help before meeting in a new country or city.', 'Break Room community can support users who are building a new local circle.', 'Privacy controls should avoid exposing housing, exact facility, or immigration-sensitive details.')
    Night = 'Schedule-aware dating content can help travel workers whose schedule issue is overnight work more than healthcare identity.'
    CTA = 'For international travel nurses, Nurse Singles should make dating feel less random and more schedule-aware.'
  }
  [ordered]@{
    Slug = 'international-nursing-students-free-dating'
    Title = 'Free Dating for Nursing Students: International Guide'
    Region = 'International'
    Category = 'Nursing students'
    Image = 'international-india-nursing-students-dating.jpg'
    Meta = 'Nursing students need free-to-start dating, privacy, safer profiles, and realistic expectations around classes and clinicals.'
    Intro = 'Nursing students often balance lectures, clinicals, exams, part-time work, and family responsibilities. A dating app for them should respect time pressure and privacy from the beginning.'
    Compare = 'Generic dating apps do not usually account for clinical rotations or student privacy. Nurse Singles can be more useful by letting students present their goals and availability without exposing school ID, clinical site, or private details.'
    Features = @('Free-to-start access helps students explore without pressure.', 'Profile prompts can explain clinical schedules and study windows.', 'Games and Break Room topics make first contact easier.', 'Safety controls should make blocking, reporting, and privacy simple.')
    Night = 'Schedule-aware dating content can be useful for students who also work overnight jobs while studying.'
    CTA = 'Nursing student content should be honest, safety-focused, and built around realistic time management.'
  }
  [ordered]@{
    Slug = 'international-healthcare-games-community'
    Title = 'Healthcare Games and Community: More Than Matching for International Singles'
    Region = 'International'
    Category = 'Games'
    Image = 'international-caribbean-healthcare-dating.jpg'
    Meta = 'Games and community features can make Nurse Singles more useful for international healthcare workers before a match.'
    Intro = 'A dating app gets stronger when users have a reason to return even before they meet someone. Games, prompts, and community spaces can help healthcare workers interact in a lighter way.'
    Compare = 'Tinder, Bumble, and Hinge are primarily broad match-and-message experiences. Nurse Singles can differentiate with healthcare-friendly games, Break Room discussions, Nurse Hub guides, and speed dating.'
    Features = @('Games can create easy icebreakers across languages and time zones.', 'Community topics can support travel, study, wellness, and shift-life discussion.', 'Speed dating can move interested users from casual contact to real connection.', 'Safety reminders should keep medical details and workplace identities protected.')
    Night = 'Schedule-aware dating content can use similar games for overnight workers who want conversation outside normal hours.'
    CTA = 'International growth should combine useful content with app features that make people come back.'
  }
  [ordered]@{
    Slug = 'international-dating-app-for-nurses-doctors'
    Title = 'Dating App for Nurses, Doctors, and Healthcare Workers: International Guide'
    Region = 'International'
    Category = 'Healthcare dating'
    Image = 'international-uk-nurses-dating.jpg'
    Meta = 'A dating app for nurses, doctors, and healthcare workers should prioritize privacy, boundaries, speed dating, and healthcare-specific context.'
    Intro = 'Healthcare workers can understand each other in ways a generic dating pool may not. But dating across roles also requires privacy, consent, and professional boundaries.'
    Compare = 'Nurse Singles can be positioned as a healthcare dating community rather than a status-based app. The focus should be free-to-start access, respectful introductions, speed dating, community features, and privacy around work.'
    Features = @('Role badges should be optional and not expose credential numbers publicly.', 'Same-workplace and same-department privacy concerns should be respected.', 'Speed dating can help users test connection without long public messages.', 'Nurse Hub content can educate users about boundaries and safer dating.')
    Night = 'Schedule-aware dating content can support users whose primary shared issue is overnight work, while Nurse Singles keeps the healthcare community focused.'
    CTA = 'The strongest healthcare dating message is simple: meet people who understand the work, while keeping professional boundaries clear.'
  }
)

function New-ArticleHtml($Post) {
  $title = Encode-Html $Post.Title
  $meta = Encode-Html $Post.Meta
  $region = Encode-Html $Post.Region
  $category = Encode-Html $Post.Category
  $image = Encode-Html $Post.Image
  $intro = Encode-Html $Post.Intro
  $compare = Encode-Html $Post.Compare
  $night = Encode-Html $Post.Night
  $cta = Encode-Html $Post.CTA
  $url = "$BaseUrl/blog/$($Post.Slug)"
  $schema = [ordered]@{
    '@context' = 'https://schema.org'
    '@type' = 'Article'
    headline = $Post.Title
    description = $Post.Meta
    datePublished = $LastMod
    dateModified = $LastMod
    image = "$BaseUrl/blog/images/$($Post.Image)"
    author = [ordered]@{ '@type' = 'Organization'; name = 'Nurse Singles' }
    publisher = [ordered]@{ '@type' = 'Organization'; name = 'Nurse Singles'; url = $BaseUrl }
    mainEntityOfPage = [ordered]@{ '@type' = 'WebPage'; '@id' = $url }
  } | ConvertTo-Json -Depth 8
  $features = ($Post.Features | ForEach-Object { "          <li>$(Encode-Html $_)</li>" }) -join "`n"
  $profileChecklist = ($Post.Features | ForEach-Object {
    "          <li>Turn this into a profile detail: $(Encode-Html $_)</li>"
  }) -join "`n"

  return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title | Nurse Singles</title>
  <meta name="description" content="$meta">
  <link rel="canonical" href="$url">
  <meta property="og:type" content="article">
  <meta property="og:title" content="$title">
  <meta property="og:description" content="$meta">
  <meta property="og:url" content="$url">
  <meta property="og:image" content="$BaseUrl/blog/images/$image">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="stylesheet" href="/blog/blog.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=__ADSENSE_PUBLISHER_ID__" crossorigin="anonymous"></script>
  <script type="application/ld+json">$schema</script>
</head>
<body>
  <header class="topbar">
    <nav class="nav" aria-label="Main navigation">
      <a class="brand" href="/">
        <span class="brand-mark">NS</span>
        <strong>Nurse Singles</strong>
      </a>
      <div class="nav-links">
        <a href="/welcome">Open App</a>
        <a href="/blog/">Nurse Hub</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
        <a href="/privacy">Privacy</a>
      </div>
    </nav>
  </header>
  <main class="wrap">
    <article class="article">
      <div class="eyebrow">$region | $category</div>
      <h1>$title</h1>
      <p>$meta</p>
      <div class="meta-row">
        <span class="chip">Free to start</span>
        <span class="chip">Speed dating</span>
        <span class="chip">Nurse Hub</span>
        <span class="chip">Break Room</span>
      </div>
      <img class="hero-image" src="/blog/images/$image" alt="$title">
      <p>$intro</p>

      <h2>Why this is different from swipe apps</h2>
      <p>$compare</p>
      <p>Generic dating apps usually begin with a photo, age, and location. Healthcare dating needs more context because the work affects sleep, social time, emotional energy, and privacy. A nurse coming off a twelve-hour night shift may need a different pace than a dental assistant on weekday hours, a doctor on call, a nursing student in clinicals, or a travel clinician between assignments.</p>
      <p>That does not mean every profile should become a resume. It means the app should make the most useful lifestyle signals easy to understand: shift type, communication window, dating goal, willingness to do a short video intro, and whether workplace details should stay private until trust is built.</p>

      <h2>Features nurses should notice</h2>
      <ul class="signal-list">
$features
      </ul>
      <p>These features matter because they answer the questions healthcare workers usually have before a conversation becomes serious. Is this person available when I am awake? Do they understand weekend shifts? Are they comfortable with slow replies after a hard day? Can we talk safely without exposing hospital, clinic, school, or credential details publicly?</p>

      <h2>Schedule-aware dating note</h2>
      <p>$night</p>
      <p>Schedule compatibility is not only about night shift. It can include rotating shifts, agency work, school clinicals, travel contracts, on-call days, long commutes, and recovery time after emotionally heavy work. A useful healthcare dating profile should make those realities understandable without making the user feel like they have to apologize for their job.</p>

      <h2>How to build a stronger profile from this guide</h2>
      <p>A strong Nurse Singles profile should be specific enough to help matching, but careful enough to protect professional boundaries. Use broad workplace language such as hospital system, clinic, dental office, school program, agency assignment, or allied health role when you do not want to show exact employer details.</p>
      <ul class="signal-list">
$profileChecklist
          <li>Add a dating goal so matches know whether you want serious dating, friendship first, video intros, or a slower pace.</li>
          <li>Use personal photos away from patients, workstations, computer screens, badges, and employer-only spaces.</li>
          <li>Keep exact license numbers, patient stories, private documents, and home or housing details out of public profile text.</li>
      </ul>

      <h2>Conversation ideas for healthcare singles</h2>
      <p>Good first messages for healthcare workers are practical and low pressure. Ask whether someone prefers messages before shift, after handoff, on off days, or during a planned window. If both people are busy, a short speed dating room or video intro can be more respectful than a week of half-finished messages.</p>
      <p>Useful conversation starters include schedule rhythm, favorite way to decompress, travel openness, city distance, wellness habits, favorite low-stress first date, and how quickly each person likes to move from chat to a real plan. Those questions help reveal compatibility without pushing anyone to share patient information or employer-confidential details.</p>

      <h2>Privacy and safety reminders</h2>
      <p>Nurse Singles is for adult dating and community, not medical advice. Users should not post patient names, room numbers, diagnoses, case details, workplace incidents, private credential documents, or screenshots from clinical systems. If a match pushes for money, explicit photos, identity documents, exact workplace details, or off-platform contact too quickly, use blocking or reporting tools.</p>
      <p>Comparison pages should also stay fair. The point is not that every broad dating app is bad. The point is that nurses and healthcare workers have specific dating needs that are easier to support when the product is built around healthcare schedules, privacy, speed dating, community, and safer introductions from the beginning.</p>

      <h2>How to turn a search visitor into a signup</h2>
      <p>$cta</p>
      <p>A visitor should leave this page understanding what problem Nurse Singles solves, who it is for, and why the app has value before login. That is why public Nurse Hub pages explain schedules, safety, privacy, games, speed dating, and community features in plain language instead of hiding all value behind an account screen.</p>

      <section class="cta" aria-label="Open Nurse Singles">
        <h2>Meet healthcare singles faster</h2>
        <p>Nurse Singles is a healthcare-focused dating and community app for adults. Use speed dating, the Nurse Hub, games, and the Break Room to find people who understand clinical schedules.</p>
        <a href="/welcome">Open Nurse Singles</a>
        <a href="/blog/">Read Nurse Hub</a>
      </section>
    </article>
  </main>
  <footer class="footer">Nurse Singles is for adults and is not medical advice. Do not share patient information or private workplace details in public profiles or chats.</footer>
</body>
</html>
"@
}

foreach ($post in $Posts) {
  $path = Join-Path 'public/blog' "$($post.Slug).html"
  Write-Utf8File $path (New-ArticleHtml $post)
}

$cards = ($Posts | ForEach-Object {
  $title = Encode-Html $_.Title
  $meta = Encode-Html $_.Meta
  $region = Encode-Html $_.Region
  $image = Encode-Html $_.Image
  $slug = Encode-Html $_.Slug
@"
      <article class="card" data-expansion="conversion">
        <img src="/blog/images/$image" alt="$title" loading="lazy">
        <div class="card-body">
          <div class="eyebrow">$region</div>
          <h2><a href="/blog/$slug">$title</a></h2>
          <p>$meta</p>
        </div>
      </article>
"@
}) -join "`n"

$blogIndexPath = 'public/blog/index.html'
$index = Get-Content -LiteralPath $blogIndexPath -Raw
$index = $index.Replace(
  '<meta name="description" content="Nurse Singles guides for nurses, nursing students, travel clinicians, doctors, and healthcare workers in the U.S. and internationally.">',
  '<meta name="description" content="Nurse Singles guides for nurses and healthcare workers comparing Tinder, Bumble, and Hinge with free-to-start speed dating, Nurse Hub, games, and Break Room community features.">'
)
$index = $index.Replace(
  'Shift-aware dating, privacy, healthcare verification, video intros, and global nurse community guides.',
  'Shift-aware dating, privacy, speed dating, Nurse Hub, games, Break Room community, and global nurse comparison guides.'
)
$index = [regex]::Replace($index, '(?s)\s*<article class="card" data-expansion="conversion">.*?</article>', '')
$index = [regex]::Replace($index, '(?s)(\s*</section>\s*</main>)', "`n$cards`n`$1", 1)
Write-Utf8File $blogIndexPath $index

$sitemapPath = 'public/sitemap.xml'
$sitemap = Get-Content -LiteralPath $sitemapPath -Raw
foreach ($post in $Posts) {
  $loc = "$BaseUrl/blog/$($post.Slug)"
  if ($sitemap -notlike "*<loc>$loc</loc>*") {
    $entry = @"
  <url>
    <loc>$loc</loc>
    <lastmod>$LastMod</lastmod>
    <changefreq>weekly</changefreq>
  </url>
"@
    $sitemap = $sitemap.Replace('</urlset>', "$entry</urlset>")
  }
}
$existingLocs = [regex]::Matches($sitemap, '<loc>(.*?)</loc>') | ForEach-Object {
  $_.Groups[1].Value
}
$newLocs = $Posts | ForEach-Object { "$BaseUrl/blog/$($_.Slug)" }
$allLocs = @($existingLocs + $newLocs) | Where-Object { $_ } | Select-Object -Unique
$sitemapEntries = ($allLocs | ForEach-Object {
@"
  <url>
    <loc>$_</loc>
    <lastmod>$LastMod</lastmod>
    <changefreq>weekly</changefreq>
  </url>
"@
}) -join "`n"
$cleanSitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$sitemapEntries
</urlset>
"@
Write-Utf8File $sitemapPath $cleanSitemap

$homePath = 'public/index.html'
$homeContent = Get-Content -LiteralPath $homePath -Raw
$homeContent = $homeContent.Replace(
  '<meta name="description" content="Nurse Singles is a healthcare dating app and nurse community for adult nurses, nursing students, travel clinicians, doctors, dental workers, and hospital staff.">',
  '<meta name="description" content="Nurse Singles is a free-to-start healthcare dating app and nurse community with speed dating, Nurse Hub guides, games, Break Room conversations, and privacy-focused profiles.">'
)
$homeContent = $homeContent.Replace(
  'Shift-aware dating, privacy controls, safety resources, and practical guides for healthcare workers.',
  'Free-to-start healthcare dating with speed dating, Nurse Hub guides, games, Break Room conversations, privacy controls, and safety resources.'
)
$homeContent = [regex]::Replace($homeContent, '(?s)\s*<!-- conversion-guides-start -->.*?<!-- conversion-guides-end -->', '')

$conversionBlock = @"
    <!-- conversion-guides-start -->
    <section class="section" aria-labelledby="comparison-title">
      <div class="eyebrow">Free nurse dating comparisons</div>
      <h2 id="comparison-title">Why nurses may choose Nurse Singles over generic swipe apps</h2>
      <p>
        Tinder, Bumble, and Hinge serve broad dating audiences. Nurse Singles is built for
        healthcare workers who need free-to-start access, speed dating, privacy around work,
        the Nurse Hub, games, and a Break Room community that understands shift life.
      </p>
      <div class="article-grid">
        <article class="article-card">
          <img src="/blog/images/us-healthcare-video-intros.jpg" alt="Nurse Singles vs Tinder guide">
          <div class="article-body">
            <h3><a href="/blog/us-nurse-singles-vs-tinder">Nurse Singles vs. Tinder</a></h3>
            <p>A healthcare-first option for nurses who want speed dating and schedule-aware context.</p>
          </div>
        </article>
        <article class="article-card">
          <img src="/blog/images/us-allied-healthcare-dating.jpg" alt="Nurse Singles vs Bumble guide">
          <div class="article-body">
            <h3><a href="/blog/us-nurse-singles-vs-bumble">Nurse Singles vs. Bumble</a></h3>
            <p>Why healthcare singles may need more than a generic profile and message queue.</p>
          </div>
        </article>
        <article class="article-card">
          <img src="/blog/images/us-doctor-nurse-dating-boundaries.jpg" alt="Nurse Singles vs Hinge guide">
          <div class="article-body">
            <h3><a href="/blog/us-nurse-singles-vs-hinge">Nurse Singles vs. Hinge</a></h3>
            <p>Serious dating for nurses with less schedule explaining and more healthcare context.</p>
          </div>
        </article>
        <article class="article-card">
          <img src="/blog/images/us-night-shift-nurse-dating.jpg" alt="Night shift dating for nurses guide">
          <div class="article-body">
            <h3><a href="/blog/us-night-shift-dating-nurse-singles">Night-Shift Dating for Nurses</a></h3>
            <p>How Nurse Singles helps healthcare workers explain availability and meet around real schedules.</p>
          </div>
        </article>
      </div>
    </section>
    <!-- conversion-guides-end -->
"@

$homeContent = $homeContent.Replace('    <section class="section" aria-labelledby="features-title">', "$conversionBlock`r`n`r`n    <section class=`"section`" aria-labelledby=`"features-title`">")
Write-Utf8File $homePath $homeContent

Write-Host "Added $($Posts.Count) Nurse Singles conversion blog pages and updated blog index, homepage, and sitemap."
