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
    Slug = 'us-night-shift-nurse-dating'
    Title = 'Night Shift Nurse Dating in the United States: Meeting Someone Who Understands Your Schedule'
    Region = 'United States'
    Category = 'Shift-aware dating'
    Image = 'us-night-shift-nurse-dating.jpg'
    Meta = 'A practical guide for night shift nurses who want dating, privacy, and conversation times that fit real hospital schedules.'
    Intro = 'Night shift dating is different. Your best window may be after handoff, before sleep, or on a weekday when everyone else is at work. Nurse Singles is built around that reality instead of forcing healthcare workers into a standard dating rhythm.'
    Angle = 'For U.S. nurses working 7p to 7a, rotating weekends, or overtime-heavy units, compatibility often starts with energy levels and quiet hours. A better profile should make your availability clear without making your workplace public.'
    Signals = @('Night shift, day shift, rotating, and flexible availability', 'Preferred dating window after shift or on off days', 'Department or specialty only when the user chooses to show it', 'Quiet hours so matches do not push for instant replies')
    Safety = 'Workplace privacy matters. Users should be able to hide hospital names, avoid coworkers, and keep license or credential details private while still showing verified healthcare status.'
    CTA = 'If you are a nurse dating around night shift schedules, start with a profile that explains your real availability and lets the app find people who can respect it.'
  }
  [ordered]@{
    Slug = 'us-travel-nurse-dating'
    Title = 'Travel Nurse Dating: How to Meet People While Moving Between Assignments'
    Region = 'United States'
    Category = 'Travel nurse dating'
    Image = 'us-travel-nurse-dating.jpg'
    Meta = 'Travel nurses need dating tools that understand assignments, temporary cities, privacy, and short windows for real connection.'
    Intro = 'Travel nursing can be exciting, but it also makes dating complicated. You may be in a city for 8, 13, or 26 weeks, and your schedule can change quickly. Nurse Singles can make assignment-based dating more practical.'
    Angle = 'The strongest travel nurse profiles explain assignment dates, preferred distance, and whether the user is open to local dating, long-distance, friendship first, or video introductions before meeting.'
    Signals = @('Current assignment city and optional next city', 'Assignment start and end dates', 'Distance preferences for short-term or long-term dating', 'Video intro availability before meeting in person')
    Safety = 'Travel nurses should never feel pressured to share housing location, exact facility, or contract details. The app should encourage meeting in public places and using in-app reporting when something feels wrong.'
    CTA = 'Use Nurse Singles to make your assignment city feel less random and more connected while still keeping your work and housing details private.'
  }
  [ordered]@{
    Slug = 'us-icu-nurse-relationships'
    Title = 'Dating as an ICU Nurse: Finding Calm Compatibility After Intense Shifts'
    Region = 'United States'
    Category = 'Specialty compatibility'
    Image = 'us-icu-nurse-relationships.jpg'
    Meta = 'ICU nurses often need calm, patient dating experiences that respect stress, decompression time, and unpredictable shifts.'
    Intro = 'ICU work is high-focus, emotionally demanding, and schedule-heavy. Dating after that kind of shift works better when the other person understands why a quick reply is not always possible.'
    Angle = 'Compatibility for ICU nurses is not only about shared hobbies. It can include communication style, decompression time, empathy after tough shifts, and whether both people understand clinical stress without turning the relationship into a work debrief.'
    Signals = @('Specialty match or adjacent specialty match', 'Preference for low-pressure messaging after shifts', 'Shared understanding of weekends, holidays, and overtime', 'Dating goals that make expectations clear early')
    Safety = 'Profiles and chats should never invite users to share patient stories or protected health information. The app can support healthcare connection without becoming a place for clinical details.'
    CTA = 'Nurse Singles can help ICU nurses meet people who respect quiet time, emotional bandwidth, and healthcare boundaries.'
  }
  [ordered]@{
    Slug = 'us-nursing-student-dating'
    Title = 'Nursing Student Dating: Balancing Clinicals, Classes, and Real Connection'
    Region = 'United States'
    Category = 'Nursing students'
    Image = 'us-nursing-student-dating.jpg'
    Meta = 'Nursing students can use safer, healthcare-focused dating tools that understand clinical rotations, exams, and early career goals.'
    Intro = 'Nursing school can feel like a full-time job before the full-time job begins. Between clinicals, exams, skills lab, and work, dating needs to be honest about limited time.'
    Angle = 'A nursing student profile should show program stage, student verification status, interests outside school, and realistic availability. It should not pressure users to share school ID numbers publicly.'
    Signals = @('Nursing Student Verified badge after private review', 'Class, clinical, and study-friendly availability', 'Dating goals and friendship-first options', 'School visibility controls for privacy')
    Safety = 'Students should have strong reporting tools, age safeguards, and clear consent expectations. The app experience should encourage respectful communication and make blocking easy.'
    CTA = 'Nurse Singles can help nursing students meet people who understand clinical schedules while keeping school and identity details protected.'
  }
  [ordered]@{
    Slug = 'us-healthcare-privacy-dating'
    Title = 'Privacy-First Dating for Healthcare Workers: What Nurses Should Expect'
    Region = 'United States'
    Category = 'Privacy and safety'
    Image = 'us-healthcare-privacy-dating.jpg'
    Meta = 'Healthcare workers need dating privacy controls for workplace names, departments, coworkers, photos, and safe reporting.'
    Intro = 'Healthcare workers carry extra privacy concerns when dating. A dating app for nurses, doctors, students, travel clinicians, and allied health staff should treat workplace privacy as a core feature.'
    Angle = 'The goal is not to hide who someone is. It is to let them show healthcare identity safely: verified status, role, interests, language, and schedule without exposing license numbers or exact workplace information.'
    Signals = @('Hide workplace name or show a general workplace type', 'Block same workplace or same department matching', 'Private credential review status', 'Photo moderation and report flows')
    Safety = 'A healthcare dating app should not store public license numbers on profiles, should limit sensitive data exposure, and should make account deletion and safety standards easy to find.'
    CTA = 'Nurse Singles is positioned around healthcare-friendly privacy controls so professionals can meet without turning their work life into public profile data.'
  }
  [ordered]@{
    Slug = 'us-er-nurse-dating'
    Title = 'ER Nurse Dating: Fast Schedules, High Energy, and Better Match Timing'
    Region = 'United States'
    Category = 'Emergency care'
    Image = 'us-er-nurse-dating.jpg'
    Meta = 'ER nurses need dating that understands unpredictable shifts, fatigue, and high-energy healthcare work.'
    Intro = 'Emergency nurses often live on unpredictable timing. A date planned after work can change because a shift runs long, a unit is short, or the day simply takes more energy than expected.'
    Angle = 'Better matching for ER nurses should focus on timing flexibility, communication patience, and whether both users understand healthcare intensity. The right app should make rescheduling normal, not awkward.'
    Signals = @('Flexible dating windows instead of fixed availability only', 'After-shift and off-day preferences', 'Specialty-aware match reasons', 'Simple video intro option before committing to a full date')
    Safety = 'Emergency workers also need strong boundaries. Profiles should avoid facility-specific details when users do not want coworkers or patients to identify them.'
    CTA = 'Nurse Singles can help ER nurses connect with people who understand fast-paced schedules and respect real recovery time.'
  }
  [ordered]@{
    Slug = 'us-rural-healthcare-dating'
    Title = 'Dating for Rural Healthcare Workers: Meeting People Beyond the Small-Town Circle'
    Region = 'United States'
    Category = 'Rural healthcare'
    Image = 'us-rural-healthcare-dating.jpg'
    Meta = 'Rural nurses, clinic staff, and healthcare workers need privacy-aware dating that expands options without exposing local workplace details.'
    Intro = 'Rural healthcare workers can face a small dating pool and higher visibility. Everyone may know the local clinic, hospital, or department, which makes privacy controls even more important.'
    Angle = 'A stronger dating experience lets rural healthcare workers widen discovery, use nearby city or region settings, and show a broad workplace category instead of an exact facility name.'
    Signals = @('Nearby region matching instead of only exact distance', 'Workplace category display such as clinic or hospital system', 'Coworker avoidance preferences', 'Video introductions before longer travel')
    Safety = 'Small communities need careful privacy. Users should have control over photos, workplace visibility, blocking, and whether people from the same department can see them.'
    CTA = 'Nurse Singles can support rural healthcare dating by combining wider discovery with workplace privacy and safer communication tools.'
  }
  [ordered]@{
    Slug = 'us-doctor-nurse-dating-boundaries'
    Title = 'Doctor and Nurse Dating: Professional Boundaries and Respectful Connection'
    Region = 'United States'
    Category = 'Professional boundaries'
    Image = 'us-doctor-nurse-dating-boundaries.jpg'
    Meta = 'Doctor and nurse dating works best when the app supports privacy, mutual consent, workplace boundaries, and clear expectations.'
    Intro = 'Healthcare professionals can meet through shared values, long shifts, and common mission. But dating across roles also needs professional boundaries, especially when people may work in the same facility.'
    Angle = 'The best experience gives users control: hide exact workplace, block same department, state dating goals, and decide how much healthcare identity to show. Respect matters more than hierarchy.'
    Signals = @('Role badges without public credential numbers', 'Same workplace and same department avoidance options', 'Match reasons based on schedule and goals, not status', 'Clear report, block, and consent tools')
    Safety = 'A hospital-friendly dating app should avoid encouraging workplace pursuit. It should make it easy for a user to say no, block, or keep work details private.'
    CTA = 'Nurse Singles can create a more respectful space for healthcare professionals by treating privacy and consent as part of the match experience.'
  }
  [ordered]@{
    Slug = 'us-allied-healthcare-dating'
    Title = 'Allied Healthcare Dating: A Better Community for Therapists, Techs, and Clinical Staff'
    Region = 'United States'
    Category = 'Allied health'
    Image = 'us-allied-healthcare-dating.jpg'
    Meta = 'Allied healthcare workers deserve dating and community features that include techs, therapists, assistants, and clinical support staff.'
    Intro = 'Healthcare is bigger than nursing and medicine. Respiratory therapists, radiology techs, surgical techs, CNAs, EMTs, pharmacy staff, and many other professionals live the same schedule pressure.'
    Angle = 'A healthcare dating app should include allied health from the start. Badges, filters, community topics, and match reasons should recognize the full care team.'
    Signals = @('Healthcare Worker Verified badge for non-nurse roles', 'Specialty and department choices across the care team', 'Shift overlap and timezone matching', 'Community feed topics beyond dating')
    Safety = 'Inclusive healthcare dating still needs privacy rules. Exact employer names, credential details, and department visibility should always be optional.'
    CTA = 'Nurse Singles can be a broader healthcare singles community while keeping nurses at the center of the brand.'
  }
  [ordered]@{
    Slug = 'us-healthcare-video-intros'
    Title = 'Healthcare Video Intros: Safer First Conversations Before Meeting In Person'
    Region = 'United States'
    Category = 'Video dating'
    Image = 'us-healthcare-video-intros.jpg'
    Meta = 'Video intros can help healthcare workers screen for respect, chemistry, and schedule fit before planning an in-person date.'
    Intro = 'A short video intro can save time for busy healthcare workers. It helps confirm basic chemistry, communication style, and whether both people understand shift life before planning a full date.'
    Angle = 'The strongest version includes clear consent, time limits, easy exit, and follow-up prompts. After a speed room, both users should choose yes before a chat connection opens.'
    Signals = @('Hospital-themed rooms by shift, role, or interest', 'Consent-based follow-up after speed dates', 'Video minute limits tied to subscription or ad rewards', 'Clear exit behavior so rooms do not stay active')
    Safety = 'Video features should have reporting, blocking, moderation paths, and privacy reminders. Users should not be pushed to share personal addresses or workplace details.'
    CTA = 'Nurse Singles can make video intros feel practical for healthcare workers by keeping calls short, consent-based, and easy to leave.'
  }
  [ordered]@{
    Slug = 'us-california-nurse-dating'
    Title = 'California Nurse Dating: Los Angeles, San Diego, Bay Area, and Travel Assignments'
    Region = 'United States'
    Category = 'California'
    Image = 'us-travel-nurse-dating.jpg'
    Meta = 'A California-focused nurse dating guide for healthcare workers balancing hospital schedules, travel assignments, city distance, and privacy.'
    Intro = 'California healthcare dating can stretch across large metro areas, long commutes, rotating shifts, and travel contracts. Nurses in Los Angeles, San Diego, Sacramento, the Bay Area, and inland cities need dating that respects real healthcare timing.'
    Angle = 'A stronger California nurse dating profile should make region, shift type, travel openness, and dating goals clear while keeping exact workplace details private.'
    Signals = @('California city or region preferences', 'Travel assignment and commute-aware dating windows', 'Day, night, rotating, and per-diem schedule signals', 'Workplace privacy controls for large hospital systems')
    Safety = 'California healthcare workers should be able to hide exact hospitals, avoid coworkers, and use video intros before committing to long-distance or cross-city meetups.'
    CTA = 'Nurse Singles can help California nurses and healthcare workers connect around schedules, region, privacy, and real availability.'
  }
  [ordered]@{
    Slug = 'us-texas-nurse-dating'
    Title = 'Texas Nurse Dating: Houston, Dallas, Austin, San Antonio, and Rural Healthcare'
    Region = 'United States'
    Category = 'Texas'
    Image = 'us-rural-healthcare-dating.jpg'
    Meta = 'A Texas healthcare dating guide for nurses, travel clinicians, students, and hospital staff across major cities and rural regions.'
    Intro = 'Texas healthcare workers can face big-city hospital systems, rural clinics, long drives, and fast-growing travel nurse markets. Dating needs to support distance, schedule, and privacy at the same time.'
    Angle = 'Texas nurse dating works better when users can show city or region, preferred dating window, healthcare role, and whether they are open to local, regional, or long-distance connection.'
    Signals = @('Houston, Dallas, Austin, San Antonio, and regional discovery options', 'Rural and metro distance preferences', 'Healthcare role and student badges', 'Video intro before longer travel')
    Safety = 'In both large hospital systems and small towns, exact workplace visibility should stay optional. Users need blocking, reporting, and privacy controls before deeper conversation.'
    CTA = 'Nurse Singles can help Texas healthcare singles meet around real schedules instead of forcing every match into a generic dating app rhythm.'
  }
  [ordered]@{
    Slug = 'us-florida-nurse-dating'
    Title = 'Florida Nurse Dating: Miami, Orlando, Tampa, Jacksonville, and Travel Healthcare'
    Region = 'United States'
    Category = 'Florida'
    Image = 'us-healthcare-video-intros.jpg'
    Meta = 'A Florida nurse dating guide for healthcare workers managing hospital shifts, travel assignments, seasonal movement, and privacy.'
    Intro = 'Florida healthcare dating can involve travel contracts, seasonal residents, busy hospital markets, and long commutes between cities. Nurses and allied health workers need a profile that makes timing and boundaries clear.'
    Angle = 'A Florida-focused experience should support city discovery, language preferences, shift type, travel openness, and safer video introductions before meeting.'
    Signals = @('Miami, Orlando, Tampa, Jacksonville, and regional filters', 'Travel assignment and seasonal schedule preferences', 'Language and dating goal options', 'Privacy controls for workplace and department details')
    Safety = 'Healthcare workers should not have to expose exact facilities, home location, or contract details to meet someone. Safer introductions and report tools matter.'
    CTA = 'Nurse Singles can help Florida nurses and healthcare workers find matches who respect work schedules, privacy, and real recovery time.'
  }
  [ordered]@{
    Slug = 'us-new-york-nurse-dating'
    Title = 'New York Nurse Dating: NYC Healthcare Schedules, Privacy, and Better Match Timing'
    Region = 'United States'
    Category = 'New York'
    Image = 'us-night-shift-nurse-dating.jpg'
    Meta = 'A New York nurse dating guide for NYC and statewide healthcare workers balancing dense schedules, commutes, privacy, and shift work.'
    Intro = 'New York healthcare workers often manage dense hospital systems, subway commutes, late-night shifts, and fast-paced social expectations. Dating works better when schedule and energy are part of matching.'
    Angle = 'A useful New York nurse dating profile should show preferred borough or region, shift pattern, communication window, and whether the user wants serious dating, friendship first, or low-pressure video intros.'
    Signals = @('NYC borough, city, and statewide region preferences', 'Night shift and commute-aware conversation windows', 'Privacy controls for workplace and coworkers', 'Short video intros before meeting')
    Safety = 'Dense cities make privacy important. Users should be able to hide workplace details, block quickly, and keep early conversations inside the app.'
    CTA = 'Nurse Singles can help New York healthcare singles connect around timing, city distance, and workplace privacy.'
  }
  [ordered]@{
    Slug = 'us-atlanta-healthcare-dating'
    Title = 'Atlanta Healthcare Dating: Nurses, Students, Travel Clinicians, and Hospital Staff'
    Region = 'United States'
    Category = 'Atlanta'
    Image = 'us-allied-healthcare-dating.jpg'
    Meta = 'An Atlanta healthcare dating guide for nurses, allied health workers, nursing students, and travel clinicians looking for schedule-aware connection.'
    Intro = 'Atlanta healthcare dating can include major hospitals, nursing programs, travel contracts, suburban distance, and busy nightlife that does not always fit clinical schedules.'
    Angle = 'A better healthcare dating experience should let Atlanta users show role, shift type, school or student status when they choose, distance preferences, and safe conversation timing.'
    Signals = @('Atlanta metro and surrounding suburb discovery', 'Healthcare worker and student badges', 'After-shift and off-day availability', 'Friendship-first, serious dating, and video intro options')
    Safety = 'Users should control whether school, employer, department, or exact workplace details appear on their profile. Safety tools should be available before meeting.'
    CTA = 'Nurse Singles can help Atlanta healthcare workers meet people who understand clinical schedules and respect boundaries.'
  }
  [ordered]@{
    Slug = 'international-uk-nurses-dating'
    Title = 'UK Nurse Dating: Building Healthcare Connections Around Shifts and Privacy'
    Region = 'International'
    Category = 'United Kingdom'
    Image = 'international-uk-nurses-dating.jpg'
    Meta = 'A guide for nurses and healthcare workers in the UK who want shift-aware dating and privacy-first profile controls.'
    Intro = 'Nurses and healthcare workers in the UK often balance long shifts, commutes, training, and family responsibilities. Dating works better when the app understands those constraints.'
    Angle = 'UK-focused healthcare dating should support shift patterns, city or region matching, privacy controls, and profile badges that communicate healthcare identity without exposing sensitive credential details.'
    Signals = @('City or region matching for London, Manchester, Birmingham, Glasgow, and more', 'Shift type and preferred conversation windows', 'Healthcare Worker Verified and Nursing Student Verified badges', 'Language and dating goal filters')
    Safety = 'Users should control whether their employer, trust, ward, or department is visible. Reporting and blocking should be simple and available from every conversation.'
    CTA = 'Nurse Singles can help UK healthcare workers meet people who understand clinical schedules while keeping privacy front and center.'
  }
  [ordered]@{
    Slug = 'international-canada-healthcare-singles'
    Title = 'Healthcare Dating in Canada: Matching Around Shift Work, Weather, and Distance'
    Region = 'International'
    Category = 'Canada'
    Image = 'international-canada-healthcare-singles.jpg'
    Meta = 'Canadian healthcare workers need dating tools that respect shift work, regional distance, weather, and privacy.'
    Intro = 'Healthcare dating in Canada can involve long commutes, winter weather, rural distance, and demanding schedules. A healthcare-first app should make those realities easier to manage.'
    Angle = 'Profiles should support timezone, city, province, rural distance, and shift availability. Video intros and messaging windows can help people connect before traveling.'
    Signals = @('Province and city discovery options', 'Timezone-aware matching across large regions', 'Video intro before longer travel', 'Privacy controls for hospital or clinic visibility')
    Safety = 'Healthcare workers should avoid sharing exact facility details until trust is established. Clear community standards and reporting tools protect the dating experience.'
    CTA = 'Nurse Singles can support Canadian healthcare singles by combining region-aware discovery with healthcare identity and privacy.'
  }
  [ordered]@{
    Slug = 'international-australia-nurses-dating'
    Title = 'Australia Nurse Dating: Shift-Aware Connections for Healthcare Workers'
    Region = 'International'
    Category = 'Australia'
    Image = 'international-australia-nurses-dating.jpg'
    Meta = 'Nurses and healthcare workers in Australia can benefit from dating that understands shifts, travel, city distance, and privacy.'
    Intro = 'Australian healthcare workers may move between metro hospitals, regional clinics, agency work, and long stretches of shift work. Dating should adapt to that schedule instead of fighting it.'
    Angle = 'A useful profile can show shift type, city or region, travel openness, and lifestyle preferences without forcing a user to publish exact employer or department details.'
    Signals = @('Metro and regional matching preferences', 'Day, night, rotating, and flexible shift options', 'Workplace privacy controls', 'Video intro and chat consent tools')
    Safety = 'Users should keep facility details optional and use in-app reporting when someone ignores boundaries or pressures for personal information too quickly.'
    CTA = 'Nurse Singles can help Australian healthcare workers find connections that fit real shift patterns and real privacy needs.'
  }
  [ordered]@{
    Slug = 'international-philippines-nurses-dating'
    Title = 'Filipino Nurse Dating: Career, Family, and Global Healthcare Connection'
    Region = 'International'
    Category = 'Philippines'
    Image = 'international-philippines-nurses-dating.jpg'
    Meta = 'Filipino nurses and healthcare workers can use healthcare-focused dating to connect around career goals, language, family values, and global mobility.'
    Intro = 'Filipino nurses are part of a global healthcare workforce. Dating can involve local relationships, overseas plans, family expectations, and long-distance communication.'
    Angle = 'A stronger app experience should support language, country, career stage, nursing student status, travel goals, and respectful video introductions before deeper connection.'
    Signals = @('Language and culture-friendly profile fields', 'Career stage and healthcare verification', 'Local and international discovery options', 'Dating goals for serious, friendship first, or long-distance')
    Safety = 'International dating needs strong scam prevention, profile reporting, and privacy rules. Users should be encouraged to keep financial and personal identity details private.'
    CTA = 'Nurse Singles can support Filipino healthcare workers by making career, culture, schedule, and safety part of the dating experience.'
  }
  [ordered]@{
    Slug = 'international-india-nursing-students-dating'
    Title = 'India Nursing Student Dating: Safe Community for Students and Healthcare Careers'
    Region = 'International'
    Category = 'India'
    Image = 'international-india-nursing-students-dating.jpg'
    Meta = 'Nursing students and healthcare workers in India need safer dating and community tools built around study, career, language, and privacy.'
    Intro = 'Nursing students in India often balance training, family expectations, language, exams, and future career plans. A healthcare-focused community can make dating feel more respectful and practical.'
    Angle = 'Profiles should support student verification, language preferences, city or state, future career goals, and privacy controls that protect school and identity details.'
    Signals = @('Nursing Student Verified badge after private review', 'Language and city discovery filters', 'Study-friendly messaging expectations', 'Community topics for careers, staffing, and education')
    Safety = 'Age checks, reporting, blocking, photo moderation, and clear safety standards are essential for any dating or social app serving students and young professionals.'
    CTA = 'Nurse Singles can help nursing students connect around shared career goals while keeping privacy and respect central.'
  }
  [ordered]@{
    Slug = 'international-caribbean-healthcare-dating'
    Title = 'Caribbean Healthcare Dating: Community, Culture, and Shift-Friendly Matching'
    Region = 'International'
    Category = 'Caribbean'
    Image = 'international-caribbean-healthcare-dating.jpg'
    Meta = 'Healthcare workers across the Caribbean can use dating and community tools that support culture, travel, privacy, and medical careers.'
    Intro = 'Healthcare work across Caribbean islands can involve close-knit communities, regional travel, and strong family and cultural ties. Dating needs to respect both connection and privacy.'
    Angle = 'A healthcare-first app can support island or region preferences, language, travel openness, and badges for healthcare workers, nursing students, travel clinicians, and agency partners.'
    Signals = @('Island, city, and regional discovery preferences', 'Healthcare role and student badges', 'Language and culture-friendly profile prompts', 'Video intro before travel-based dating')
    Safety = 'In smaller communities, privacy controls are not optional. Users should be able to hide exact employer, avoid coworkers, and report unsafe behavior quickly.'
    CTA = 'Nurse Singles can become a healthcare-friendly community for Caribbean professionals who want connection without giving up privacy.'
  }
  [ordered]@{
    Slug = 'international-middle-east-healthcare-expats'
    Title = 'Healthcare Expat Dating in the Middle East: Privacy and Respect First'
    Region = 'International'
    Category = 'Middle East'
    Image = 'international-middle-east-healthcare-expats.jpg'
    Meta = 'Healthcare expats in the Middle East need privacy-aware dating tools that respect culture, work schedules, and personal safety.'
    Intro = 'Many nurses, doctors, and allied health professionals work abroad in the Middle East. Dating as an expat can involve cultural expectations, privacy needs, and schedule pressure.'
    Angle = 'A responsible app should support country and city settings, language, professional verification, and careful privacy controls so users can decide what to reveal and when.'
    Signals = @('City and country discovery controls', 'Language and faith or lifestyle preferences when users choose to show them', 'Healthcare verification without public credential exposure', 'Video intro and safer messaging options')
    Safety = 'International expat dating should be cautious about public employer details, housing location, financial requests, and off-app pressure. Reporting tools should be easy to find.'
    CTA = 'Nurse Singles can support healthcare expats by combining professional identity, cultural respect, and strong privacy controls.'
  }
  [ordered]@{
    Slug = 'international-africa-nurses-dating'
    Title = 'Africa Nurse Dating: Healthcare Community Across Cities, Regions, and Careers'
    Region = 'International'
    Category = 'Africa'
    Image = 'international-africa-nurses-dating.jpg'
    Meta = 'Nurses and healthcare workers across Africa can benefit from dating and community tools that support career growth, privacy, and regional connection.'
    Intro = 'Healthcare workers across African cities and regions often balance demanding work, family, education, and career growth. A healthcare-focused dating app should support that full picture.'
    Angle = 'The best experience can combine dating, professional identity, student pathways, travel, language, and healthcare community content without exposing private workplace details.'
    Signals = @('Country, city, and regional matching options', 'Nurse, student, doctor, allied health, and travel clinician badges', 'Language and dating goal preferences', 'Community hub for education, staffing, and healthcare news')
    Safety = 'Privacy, photo moderation, scam reporting, and account deletion must be clear. Users should never have to publish credential numbers or exact workplaces to build trust.'
    CTA = 'Nurse Singles can serve healthcare workers across Africa with respectful dating, helpful community features, and practical privacy controls.'
  }
  [ordered]@{
    Slug = 'international-europe-healthcare-workers-dating'
    Title = 'European Healthcare Worker Dating: Multilingual Matching With Professional Privacy'
    Region = 'International'
    Category = 'Europe'
    Image = 'international-europe-healthcare-workers-dating.jpg'
    Meta = 'European healthcare workers need multilingual, privacy-first dating that works across cities, borders, roles, and schedules.'
    Intro = 'Healthcare workers across Europe often speak multiple languages, work across borders, and manage varied shift systems. Dating can work better when those details are part of matching.'
    Angle = 'A useful app should support language filters, country and city discovery, timezone, shift type, and privacy rules for workplace and department visibility.'
    Signals = @('Language compatibility and multilingual profiles', 'Country, city, and cross-border discovery', 'Shift and timezone-aware matching', 'Healthcare verification and workplace privacy options')
    Safety = 'Users should have transparent reporting, blocking, and data deletion options. For healthcare professionals, exact employer and credential visibility should always be controlled by the user.'
    CTA = 'Nurse Singles can help European healthcare workers connect through language, schedule, role, and safety-aware privacy controls.'
  }
  [ordered]@{
    Slug = 'international-global-travel-nurse-dating'
    Title = 'Global Travel Nurse Dating: Building Connection Across Assignments and Borders'
    Region = 'International'
    Category = 'Global travel'
    Image = 'international-global-travel-nurse-dating.jpg'
    Meta = 'Global travel nurses need dating tools for assignments, languages, timezones, video intros, and privacy-first connection.'
    Intro = 'Global travel nurses live in motion. Dating may start in one city, continue through video, and grow across borders. A normal dating app often misses the schedule and mobility side of that life.'
    Angle = 'A healthcare-first app can support assignment timelines, timezone-aware messaging, language compatibility, video intros, and serious relationship goals for people who understand travel healthcare.'
    Signals = @('Assignment dates and next destination fields', 'Timezone and language-aware communication', 'Video intros before long-distance commitment', 'Privacy controls for employer, housing, and travel details')
    Safety = 'Global dating needs strong scam prevention, private credential review, content reporting, and reminders not to share financial or identity details too quickly.'
    CTA = 'Nurse Singles can make global travel nurse dating more realistic by centering mobility, safety, healthcare identity, and consent-based connection.'
  }
  [ordered]@{
    Slug = 'international-uae-nurse-dating'
    Title = 'UAE Nurse Dating: Dubai, Abu Dhabi, Healthcare Expats, and Privacy'
    Region = 'International'
    Category = 'UAE'
    Image = 'international-middle-east-healthcare-expats.jpg'
    Meta = 'A UAE nurse dating guide for healthcare expats and local healthcare workers in Dubai, Abu Dhabi, and nearby cities.'
    Intro = 'Healthcare workers in the UAE may balance expat life, long shifts, cultural expectations, and privacy concerns. Dating should feel respectful, careful, and schedule-aware.'
    Angle = 'A UAE-focused healthcare dating profile should support city, language, dating goals, role verification, and privacy controls without exposing employer, housing, or credential details publicly.'
    Signals = @('Dubai, Abu Dhabi, Sharjah, and regional discovery', 'Language and lifestyle preferences when users choose to show them', 'Healthcare worker and student verification', 'Video intro before meeting in person')
    Safety = 'International healthcare dating should warn users against financial requests, off-app pressure, and oversharing workplace or housing information.'
    CTA = 'Nurse Singles can support UAE healthcare singles with professional identity, safer introductions, and privacy-first matching.'
  }
  [ordered]@{
    Slug = 'international-saudi-arabia-nurse-dating'
    Title = 'Saudi Arabia Nurse Dating: Healthcare Expats, Privacy, and Respectful Connection'
    Region = 'International'
    Category = 'Saudi Arabia'
    Image = 'international-middle-east-healthcare-expats.jpg'
    Meta = 'A Saudi Arabia healthcare dating guide for nurses, hospital workers, and expats who need privacy-aware, respectful connection.'
    Intro = 'Nurses and healthcare workers in Saudi Arabia can face demanding shifts, expat distance from home, and cultural expectations around privacy. Dating tools should treat those realities carefully.'
    Angle = 'A Saudi Arabia healthcare dating experience should prioritize privacy, language preferences, city or region selection, and respectful communication before any in-person meeting.'
    Signals = @('City and region discovery for healthcare workers', 'Language and dating goal preferences', 'Healthcare identity without public credential exposure', 'Consent-based video introductions')
    Safety = 'Users should keep employer details, housing location, financial information, and personal documents private. Reporting and blocking should be easy.'
    CTA = 'Nurse Singles can help healthcare workers in Saudi Arabia connect carefully around role, schedule, culture, and privacy.'
  }
  [ordered]@{
    Slug = 'international-germany-nurse-dating'
    Title = 'Germany Nurse Dating: Healthcare Workers, Language, Shifts, and City Matching'
    Region = 'International'
    Category = 'Germany'
    Image = 'international-europe-healthcare-workers-dating.jpg'
    Meta = 'A Germany healthcare dating guide for nurses, clinical staff, and international healthcare workers balancing language, shifts, and privacy.'
    Intro = 'Healthcare workers in Germany may manage rotating shifts, multilingual communication, city distance, and international career moves. Dating works better when language and schedule are visible in the match.'
    Angle = 'A useful profile should support German and other language preferences, city or region, healthcare role, shift type, and workplace privacy.'
    Signals = @('Berlin, Munich, Hamburg, Frankfurt, Cologne, and regional discovery', 'Language compatibility and timezone-aware messaging', 'Shift and specialty signals', 'Workplace privacy controls')
    Safety = 'Users should control exact workplace visibility and keep identity documents or credential details out of public profile fields.'
    CTA = 'Nurse Singles can help healthcare workers in Germany connect through language, schedule, role, and privacy-aware matching.'
  }
  [ordered]@{
    Slug = 'international-ireland-nurse-dating'
    Title = 'Ireland Nurse Dating: Healthcare Workers, Hospital Shifts, and Safer Introductions'
    Region = 'International'
    Category = 'Ireland'
    Image = 'international-uk-nurses-dating.jpg'
    Meta = 'An Ireland nurse dating guide for healthcare workers who want shift-aware matching, city discovery, privacy, and respectful communication.'
    Intro = 'Nurses and healthcare workers in Ireland can balance hospital shifts, training, commutes, and close community visibility. Dating should protect privacy while supporting real connection.'
    Angle = 'Ireland-focused healthcare dating should support city and regional preferences, shift type, dating goals, and workplace privacy for nurses, students, doctors, and allied health workers.'
    Signals = @('Dublin, Cork, Galway, Limerick, and regional discovery', 'Day, night, and rotating shift matching', 'Healthcare worker and student badges', 'Privacy controls for employer and department')
    Safety = 'In close communities, exact workplace and department details should stay optional. Users need easy report, block, and account deletion paths.'
    CTA = 'Nurse Singles can help healthcare singles in Ireland meet around real schedules and safer introductions.'
  }
  [ordered]@{
    Slug = 'international-new-zealand-nurse-dating'
    Title = 'New Zealand Nurse Dating: Healthcare Singles, Regional Distance, and Privacy'
    Region = 'International'
    Category = 'New Zealand'
    Image = 'international-australia-nurses-dating.jpg'
    Meta = 'A New Zealand nurse dating guide for healthcare workers managing regional distance, hospital schedules, travel, and privacy.'
    Intro = 'Healthcare workers in New Zealand may deal with regional distance, shift work, travel between cities, and smaller community visibility. Dating needs to account for both distance and privacy.'
    Angle = 'A New Zealand healthcare dating profile should make region, shift type, travel openness, language, and dating goals clear without forcing exact employer details into public view.'
    Signals = @('Auckland, Wellington, Christchurch, and regional discovery', 'Distance and travel openness preferences', 'Shift-aware messaging windows', 'Privacy controls for workplace visibility')
    Safety = 'Smaller communities need careful privacy options. Users should be able to hide workplace details, block quickly, and keep early communication inside the app.'
    CTA = 'Nurse Singles can help New Zealand healthcare singles connect around role, region, schedule, and privacy.'
  }
)

$PublicRoot = Join-Path (Get-Location) 'public'
$BlogRoot = Join-Path $PublicRoot 'blog'
$ImageBase = "$BaseUrl/blog/images"

$css = @'
:root {
  color-scheme: light;
  --ink: #102a35;
  --muted: #56717a;
  --line: #d7e7ea;
  --teal: #0d827a;
  --blue: #0877b9;
  --coral: #e55d5d;
  --bg: #f5fbfb;
  --card: #ffffff;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: Arial, Helvetica, sans-serif;
  color: var(--ink);
  background: linear-gradient(180deg, #effafa 0%, #ffffff 42%, #f7fbfc 100%);
  line-height: 1.65;
}
a { color: var(--blue); font-weight: 700; text-decoration-thickness: 2px; text-underline-offset: 3px; }
.topbar {
  border-bottom: 1px solid var(--line);
  background: rgba(255,255,255,.92);
  position: sticky;
  top: 0;
  z-index: 3;
  backdrop-filter: blur(10px);
}
.nav {
  max-width: 1120px;
  margin: 0 auto;
  padding: 14px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.brand { display: flex; align-items: center; gap: 10px; color: var(--ink); text-decoration: none; }
.brand-mark {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--teal), var(--blue));
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 800;
}
.nav-links { display: flex; gap: 14px; flex-wrap: wrap; justify-content: flex-end; }
.nav-links a { color: var(--muted); text-decoration: none; font-size: 14px; }
.wrap { max-width: 1040px; margin: 0 auto; padding: 44px 20px 64px; }
.article { max-width: 820px; margin: 0 auto; }
.eyebrow { color: var(--teal); font-weight: 800; text-transform: uppercase; letter-spacing: .08em; font-size: 12px; }
h1 { margin: 10px 0 14px; font-size: clamp(34px, 6vw, 58px); line-height: 1.04; letter-spacing: 0; }
h2 { margin: 34px 0 10px; font-size: clamp(23px, 4vw, 32px); line-height: 1.18; }
p { margin: 0 0 18px; color: var(--muted); font-size: 18px; }
.hero-image {
  width: 100%;
  max-height: 540px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid var(--line);
  box-shadow: 0 18px 55px rgba(9, 63, 78, .14);
  margin: 24px 0 28px;
}
.meta-row { display: flex; gap: 10px; flex-wrap: wrap; margin: 18px 0 0; }
.chip {
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--muted);
  border-radius: 999px;
  padding: 7px 11px;
  font-size: 13px;
  font-weight: 700;
}
.signal-list {
  display: grid;
  gap: 10px;
  padding: 0;
  margin: 14px 0 24px;
  list-style: none;
}
.signal-list li {
  border-left: 4px solid var(--teal);
  background: white;
  padding: 12px 14px;
  border-radius: 6px;
  box-shadow: 0 8px 25px rgba(16, 42, 53, .06);
  color: var(--ink);
}
.cta {
  margin-top: 36px;
  padding: 24px;
  border-radius: 8px;
  background: linear-gradient(135deg, #0d827a, #0877b9);
  color: white;
}
.cta p { color: rgba(255,255,255,.9); }
.cta a {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  padding: 0 16px;
  border-radius: 6px;
  background: white;
  color: #086b72;
  text-decoration: none;
  margin-right: 10px;
  margin-top: 8px;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 18px;
}
.card {
  background: white;
  border: 1px solid var(--line);
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 12px 32px rgba(16, 42, 53, .08);
}
.card img { width: 100%; height: 180px; object-fit: cover; display: block; }
.card-body { padding: 18px; }
.card h2 { margin: 0 0 8px; font-size: 22px; }
.card p { font-size: 15px; }
.footer { border-top: 1px solid var(--line); padding: 28px 20px; text-align: center; color: var(--muted); }
@media (max-width: 640px) {
  .nav { align-items: flex-start; flex-direction: column; }
  .nav-links { justify-content: flex-start; }
  .wrap { padding-top: 30px; }
  p { font-size: 16px; }
}
'@

Write-Utf8File (Join-Path $BlogRoot 'blog.css') $css

$cards = New-Object System.Collections.Generic.List[string]
$sitemapUrls = New-Object System.Collections.Generic.List[string]
$sitemapUrls.Add($BaseUrl)
$sitemapUrls.Add("$BaseUrl/privacy")
$sitemapUrls.Add("$BaseUrl/terms")
$sitemapUrls.Add("$BaseUrl/account-deletion")
$sitemapUrls.Add("$BaseUrl/child-safety-standards")
$sitemapUrls.Add("$BaseUrl/about")
$sitemapUrls.Add("$BaseUrl/contact")
$sitemapUrls.Add("$BaseUrl/blog/")

foreach ($post in $Posts) {
  $slug = $post.Slug
  $title = Encode-Html $post.Title
  $meta = Encode-Html $post.Meta
  $intro = Encode-Html $post.Intro
  $angle = Encode-Html $post.Angle
  $safety = Encode-Html $post.Safety
  $cta = Encode-Html $post.CTA
  $region = Encode-Html $post.Region
  $category = Encode-Html $post.Category
  $canonical = "$BaseUrl/blog/$slug"
  $imagePath = "/blog/images/$($post.Image)"
  $imageUrl = "$ImageBase/$($post.Image)"
  $signals = ($post.Signals | ForEach-Object { "          <li>$(Encode-Html $_)</li>" }) -join "`n"
  $practicalChecklist = ($post.Signals | ForEach-Object {
    "          <li>Use your profile to explain how `"$([System.Net.WebUtility]::HtmlEncode($_).ToLowerInvariant())`" affects your real availability and boundaries.</li>"
  }) -join "`n"
  $jsonLd = [ordered]@{
    '@context' = 'https://schema.org'
    '@type' = 'BlogPosting'
    headline = $post.Title
    description = $post.Meta
    image = $imageUrl
    datePublished = $LastMod
    dateModified = $LastMod
    author = [ordered]@{
      '@type' = 'Organization'
      name = 'Nurse Singles'
      url = $BaseUrl
    }
    publisher = [ordered]@{
      '@type' = 'Organization'
      name = 'Nurse Singles'
      url = $BaseUrl
    }
    mainEntityOfPage = $canonical
  } | ConvertTo-Json -Depth 8

  $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title | Nurse Singles</title>
  <meta name="description" content="$meta">
  <link rel="canonical" href="$canonical">
  <meta property="og:type" content="article">
  <meta property="og:title" content="$title">
  <meta property="og:description" content="$meta">
  <meta property="og:image" content="$imageUrl">
  <meta property="og:url" content="$canonical">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="stylesheet" href="/blog/blog.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4142591817172956" crossorigin="anonymous"></script>
  <script type="application/ld+json">$jsonLd</script>
</head>
<body>
  <header class="topbar">
    <nav class="nav" aria-label="Main navigation">
      <a class="brand" href="/">
        <span class="brand-mark">NS</span>
        <strong>Nurse Singles</strong>
      </a>
      <div class="nav-links">
        <a href="/blog/">Nurse Hub</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
        <a href="/privacy">Privacy</a>
        <a href="/child-safety-standards">Safety</a>
        <a href="/welcome">Open App</a>
      </div>
    </nav>
  </header>
  <main class="wrap">
    <article class="article">
      <div class="eyebrow">$region / $category</div>
      <h1>$title</h1>
      <p>$meta</p>
      <div class="meta-row">
        <span class="chip">Healthcare dating</span>
        <span class="chip">Shift-aware matching</span>
        <span class="chip">Privacy-first profiles</span>
      </div>
      <img class="hero-image" src="$imagePath" alt="$title" loading="eager">
      <p>$intro</p>

      <h2>Why Healthcare Dating Needs Its Own Rules</h2>
      <p>$angle</p>
      <p>Healthcare schedules are rarely simple. Weekends, holidays, nights, call shifts, clinical rotations, agency contracts, and overtime can all affect when someone has energy to talk or meet. A better dating experience should treat those details as normal instead of making users explain them over and over.</p>
      <p>Generic dating apps often focus on age, distance, and a few photos. Healthcare workers usually need more context before a conversation feels worth the time. A nurse coming off three nights in a row may not want the same communication pace as a dental assistant on weekday hours, a travel clinician between contracts, or a nursing student preparing for clinicals. That is why role, schedule, privacy, and intent need to be part of the first impression.</p>

      <h2>Signals That Make Matching More Useful</h2>
      <ul class="signal-list">
$signals
      </ul>
      <p>These signals help create better introductions because they connect people around rhythm, respect, goals, and communication style. They also reduce wasted messages from people who do not understand healthcare life.</p>
      <p>Good profile signals should not feel like an interview. They should help another person understand when to message, what kind of date is realistic, and how quickly to move from chat to video or an in-person plan. The best signals are specific enough to be useful, but private enough that users do not have to expose exact employer, patient, license, or housing details.</p>

      <h2>Profile Checklist for This Situation</h2>
      <p>A stronger profile for this topic should answer practical questions without oversharing. Before messaging, another user should understand your schedule rhythm, the kind of connection you want, and what information you prefer to keep private until trust is built.</p>
      <ul class="signal-list">
$practicalChecklist
          <li>Choose a dating goal that matches your season of life, whether that is serious dating, friendship first, video intros, or a slower pace.</li>
          <li>Keep your exact workplace, license numbers, patient details, and home location out of public profile text.</li>
      </ul>

      <h2>Conversation Starters That Respect Healthcare Life</h2>
      <p>Healthcare workers often respond better to practical, low-pressure messages. Instead of asking why someone was unavailable, ask whether they prefer messages before shift, after handoff, or on off days. Instead of pushing for an immediate meetup, suggest a short video intro or a planned conversation window when both people are rested.</p>
      <p>Respectful questions can also reveal compatibility quickly: what type of schedule feels sustainable, whether travel assignments are temporary or long term, how someone decompresses after work, and what kind of relationship pace feels realistic. These questions keep the focus on dating fit without turning the conversation into a clinical debrief.</p>

      <h2>Privacy and Safety Come First</h2>
      <p>$safety</p>
      <p>For healthcare workers, safety also means workplace boundaries. A profile can show that someone is verified without revealing license numbers, exact employer details, patient information, or private documents. Users should be able to report, block, delete accounts, and control what is visible.</p>
      <p>Users should be especially careful with photos taken at work. Even when no patient is visible, badges, hallway signs, computer screens, room numbers, and employer logos can reveal more than intended. A safer dating profile uses personal photos, neutral backgrounds, and optional broad workplace labels instead of exact facility names.</p>

      <h2>What to Avoid Sharing Publicly</h2>
      <p>Do not post patient stories, protected health information, medical record details, facility incidents, private credential documents, exact housing information, or employer-confidential details. Healthcare connection should be built around shared lifestyle and values, not sensitive work information.</p>
      <p>If a match asks for money, personal identity documents, off-platform contact too quickly, explicit images, or exact workplace details, pause the conversation and use blocking or reporting tools when needed. A dating app for healthcare workers should make safety feel normal, not awkward.</p>

      <h2>How Nurse Singles Can Help</h2>
      <p>Nurse Singles is built for nurses, nursing students, travel clinicians, doctors, and healthcare workers who want connection with people who understand the work. The app can support shift-aware matching, healthcare badges, video intros, community content, and safer follow-up after speed dating rooms.</p>
      <p>$cta</p>
      <p>The goal is to make healthcare dating feel more intentional: better timing, clearer expectations, safer privacy choices, and more useful reasons to start a conversation. Whether someone works in a hospital, clinic, dental office, school program, agency role, or travel assignment, the app should help them meet people without giving up professional boundaries.</p>

      <section class="cta" aria-label="Try Nurse Singles">
        <h2>Join the Healthcare Singles Community</h2>
        <p>Create a profile built around your role, your schedule, your privacy settings, and the kind of connection you want.</p>
        <a href="/welcome">Open Nurse Singles</a>
        <a href="/blog/">Read More</a>
      </section>
    </article>
  </main>
  <footer class="footer">Nurse Singles is a dating and community app for adult healthcare workers and nursing students.</footer>
</body>
</html>
"@

  Write-Utf8File (Join-Path $BlogRoot "$slug.html") $html
  $sitemapUrls.Add($canonical)

  $cards.Add(@"
      <article class="card">
        <img src="/blog/images/$($post.Image)" alt="$title" loading="lazy">
        <div class="card-body">
          <div class="eyebrow">$region</div>
          <h2><a href="/blog/$slug">$title</a></h2>
          <p>$meta</p>
        </div>
      </article>
"@)
}

$blogIndexJson = [ordered]@{
  '@context' = 'https://schema.org'
  '@type' = 'Blog'
  name = 'Nurse Singles Nurse Hub'
  url = "$BaseUrl/blog/"
  description = 'Healthcare dating, nurse community, privacy, shift-aware matching, and international nursing lifestyle guides.'
  publisher = [ordered]@{
    '@type' = 'Organization'
    name = 'Nurse Singles'
    url = $BaseUrl
  }
} | ConvertTo-Json -Depth 8

$cardsHtml = $cards -join "`n"
$blogIndex = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Nurse Hub: Dating and Community Guides for Healthcare Workers | Nurse Singles</title>
  <meta name="description" content="Nurse Singles guides for nurses, nursing students, travel clinicians, doctors, and healthcare workers in the U.S. and internationally.">
  <link rel="canonical" href="$BaseUrl/blog/">
  <meta property="og:type" content="website">
  <meta property="og:title" content="Nurse Hub: Dating and Community Guides for Healthcare Workers">
  <meta property="og:description" content="Shift-aware dating, privacy, healthcare verification, video intros, and global nurse community guides.">
  <meta property="og:url" content="$BaseUrl/blog/">
  <meta name="twitter:card" content="summary">
  <link rel="stylesheet" href="/blog/blog.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4142591817172956" crossorigin="anonymous"></script>
  <script type="application/ld+json">$blogIndexJson</script>
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
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
        <a href="/privacy">Privacy</a>
        <a href="/child-safety-standards">Safety</a>
      </div>
    </nav>
  </header>
  <main class="wrap">
    <section class="article">
      <div class="eyebrow">Nurse Hub</div>
      <h1>Dating and Community Guides for Healthcare Workers</h1>
      <p>Practical guides for nurses, nursing students, travel clinicians, doctors, allied health professionals, and healthcare singles who want safer connection around real schedules.</p>
    </section>
    <section class="grid" aria-label="Blog posts">
$cardsHtml
    </section>
  </main>
  <footer class="footer">Nurse Singles is built for adult healthcare workers, privacy-first profiles, and shift-aware connection.</footer>
</body>
</html>
"@

Write-Utf8File (Join-Path $BlogRoot 'index.html') $blogIndex

$robots = @"
User-agent: *
Allow: /

Sitemap: $BaseUrl/sitemap.xml
"@
Write-Utf8File (Join-Path $PublicRoot 'robots.txt') $robots

$sitemapEntries = ($sitemapUrls | ForEach-Object {
@"
  <url>
    <loc>$_</loc>
    <lastmod>$LastMod</lastmod>
    <changefreq>weekly</changefreq>
  </url>
"@
}) -join "`n"

$sitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$sitemapEntries
</urlset>
"@
Write-Utf8File (Join-Path $PublicRoot 'sitemap.xml') $sitemap

Write-Host "Generated $($Posts.Count) blog posts, blog index, robots.txt, and sitemap.xml."
