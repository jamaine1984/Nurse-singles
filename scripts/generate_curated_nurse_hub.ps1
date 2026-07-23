$ErrorActionPreference = 'Stop'

$published = '2026-07-22'
$publisherId = '__ADSENSE_PUBLISHER_ID__'
$outputRoot = Join-Path $PSScriptRoot '..\public\blog'

$articles = @(
  [pscustomobject]@{
    Slug = 'us-night-shift-nurse-dating'
    Title = 'Night Shift Dating: A Practical Guide for Healthcare Workers'
    Description = 'A practical dating guide for nurses and healthcare workers balancing overnight shifts, recovery sleep, communication windows, and short first dates.'
    Eyebrow = 'Schedule planning / Night shift'
    Image = 'us-night-shift-nurse-dating.jpg'
    Tags = @('Night shift', 'Schedule compatibility', 'First dates')
    Body = @'
<p>Night shift changes more than bedtime. It changes when a person has social energy, when a message feels welcome, and whether a date scheduled at a normal hour is actually realistic. The useful question is not simply, "Do you work nights?" It is, "What does your week feel like before, during, and after those nights?"</p>

<h2>Start with a seven-day schedule map</h2>
<p>Before planning a date, describe the rhythm of a typical work block in plain language. A three-night stretch may include a preparation afternoon, three overnight shifts, a recovery morning, and one day that looks free on a calendar but does not feel free. Rotating schedules need even more context because the best communication window may change every week.</p>
<div class="planner-grid">
  <div><strong>Before the first shift</strong><span>Good for planning, groceries, and a short call. Often poor for a long evening date.</span></div>
  <div><strong>Between shifts</strong><span>Protect sleep. Use low-pressure messages that do not require an immediate answer.</span></div>
  <div><strong>Recovery day</strong><span>Keep plans flexible. A coffee or walk is easier to move than a ticketed event.</span></div>
  <div><strong>True day off</strong><span>Best for a longer date once both people understand the schedule.</span></div>
</div>

<h2>Put communication windows on the profile</h2>
<p>A profile can say "Night shift" and still leave another person guessing. A more useful line is: "I work three nights most weeks. I usually answer before 7 p.m. or after I wake up in the afternoon." That gives a match permission to communicate without treating delayed replies as disinterest.</p>
<p>Quiet hours should be specific enough to help but not so specific that they reveal an exact workplace routine. A broad range such as "sleeping late mornings after shift" is safer than posting a detailed schedule, facility name, floor, and commute.</p>

<h2>Use the smallest date that can still feel intentional</h2>
<p>Night-shift dating works better when the first plan is easy to complete. A 35-minute coffee, breakfast after a final shift, bookstore walk, early dinner, or short video introduction can establish chemistry without asking either person to sacrifice recovery sleep. The goal is not to make the date disposable. It is to lower the scheduling cost of finding out whether a second date makes sense.</p>
<ul class="signal-list">
  <li>Choose a location that is open during the actual overlap, not just during standard evening hours.</li>
  <li>Set an end time before the date so leaving does not feel rude.</li>
  <li>Avoid scheduling immediately after a difficult shift when either person is too tired to drive safely.</li>
  <li>Confirm the plan once, then allow for clinical overtime or an unexpected handoff without guilt.</li>
</ul>

<h2>Separate availability from interest</h2>
<p>A person can be interested and still be unavailable for twelve hours. Look for consistent effort over several days rather than instant response speed. Useful signs include proposing another time after canceling, remembering the other person's schedule, and choosing a communication rhythm both people can maintain.</p>
<p>Repeated silence with no attempt to reschedule is different from a planned quiet period. Naming that distinction early prevents one person from feeling ignored and the other from feeling monitored.</p>

<h2>Match on recovery style, not only shift label</h2>
<p>Two night-shift workers are not automatically compatible. One may want breakfast and conversation after work; another may need immediate quiet. One may stack shifts to create several days off; another may rotate unpredictably. Ask how someone decompresses, what a sustainable weekend looks like, and whether they prefer spontaneous or scheduled plans.</p>

<h2>Protect workplace and patient privacy</h2>
<p>Do not use patient stories as conversation material, even when names are omitted. Avoid work photos that show badges, computer screens, room numbers, charts, or identifiable facility details. A healthcare role can be part of a dating identity without turning clinical work into public content.</p>

<section class="callout">
  <h2>A simple message that respects night shift</h2>
  <p>"I saw that you work nights. No rush to answer while you are sleeping. Would a short coffee on your next real day off feel better than an evening plan?"</p>
</section>

<h2>Night-shift profile checklist</h2>
<ul class="signal-list">
  <li>Show day, night, rotating, or flexible shift status.</li>
  <li>Add a broad preferred dating window.</li>
  <li>Set quiet hours without publishing exact workplace movements.</li>
  <li>Choose whether coworkers or the same department should be excluded.</li>
  <li>Use a short video intro when schedules make an immediate meeting difficult.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'us-healthcare-privacy-dating'
    Title = 'Healthcare Dating Privacy: What to Show, Hide, and Verify'
    Description = 'A privacy guide for healthcare dating profiles covering workplace visibility, badges, photos, credential review, coworker matching, and patient confidentiality.'
    Eyebrow = 'Privacy / Professional boundaries'
    Image = 'us-healthcare-privacy-dating.jpg'
    Tags = @('Workplace privacy', 'Verification', 'Profile photos')
    Body = @'
<p>A healthcare dating profile needs enough detail to feel trustworthy without becoming a directory of someone's employer, license, schedule, and daily location. Good privacy design gives users separate controls for professional identity, workplace visibility, credential review, and discovery.</p>

<h2>Professional identity is not the same as employer identity</h2>
<p>A person may want to show that they are a registered nurse, dental hygienist, radiologic technologist, physician, respiratory therapist, nursing student, or hospital support professional. That does not require publishing an exact hospital, clinic, school placement, agency client, department, or license number.</p>
<p>Broad labels are often enough for early matching: "large hospital system," "outpatient clinic," "dental practice," "long-term care," or "healthcare student." Exact details can be shared later when trust and context exist.</p>

<h2>Use layered workplace controls</h2>
<div class="planner-grid">
  <div><strong>Profile visibility</strong><span>Choose whether a workplace type, employer name, or no workplace information appears publicly.</span></div>
  <div><strong>Coworker exclusion</strong><span>Prevent discovery by people associated with the same workplace when both records support that rule.</span></div>
  <div><strong>Department exclusion</strong><span>Use when avoiding a direct clinical or reporting relationship matters.</span></div>
  <div><strong>Location precision</strong><span>Show a city or general area instead of an exact facility or current position.</span></div>
</div>

<h2>Keep credential review private</h2>
<p>A verification badge should communicate the result of a review, not expose the document used to complete it. Public profiles should not display license numbers, student IDs, employee IDs, credential images, or reviewer notes. Access to submitted documents should be limited, logged, retained only as long as necessary, and governed by a clear deletion process.</p>
<p>Verification also needs accurate language. "Healthcare Worker Verified" should mean that the app completed the review it describes. It should not imply a government endorsement, a background check that never occurred, or a guarantee about character.</p>

<h2>Audit every photo before uploading</h2>
<p>Workplace photos can disclose more than the person notices. Crop and background checks should look for patient names, room boards, whiteboards, wristbands, badges, medication labels, monitor screens, uniforms with exact facility logos, and reflections that reveal protected information.</p>
<ul class="signal-list">
  <li>Prefer personal photos taken away from patient-care areas.</li>
  <li>Remove badge reels and identification cards before taking profile photos.</li>
  <li>Do not upload clinical images, even when they seem anonymous.</li>
  <li>Check mirrors, windows, and screens in the background.</li>
  <li>Use in-app reporting when another profile exposes patient or employee information.</li>
</ul>

<h2>Understand what HIPAA does and does not say</h2>
<p>HIPAA regulates protected health information held by covered entities and business associates. It is not a general privacy label for every dating app feature, and employment records are treated differently from patient records. Nurse Singles should describe concrete safeguards instead of claiming that every social interaction is "HIPAA certified."</p>
<p>For authoritative information, review the U.S. Department of Health and Human Services pages on <a href="https://www.hhs.gov/hipaa/for-professionals/privacy/index.html" rel="noopener noreferrer">the HIPAA Privacy Rule</a> and <a href="https://www.hhs.gov/hipaa/for-individuals/employers-health-information-workplace/index.html" rel="noopener noreferrer">health information in the workplace</a>.</p>

<h2>Professional guidance still applies off shift</h2>
<p>The National Council of State Boards of Nursing publishes guidance about social media, patient confidentiality, and professional boundaries. Dating profiles are personal, but nurses and students still need to consider employer policies and professional obligations before posting work-related information. See the <a href="https://www.ncsbn.org/brochures-and-posters/nurses-guide-to-the-use-of-socialmedia" rel="noopener noreferrer">NCSBN guide to social media</a>.</p>

<section class="callout">
  <h2>The first-disclosure rule</h2>
  <p>Share the least precise information needed for the current stage of the relationship. Role and broad schedule may help matching. Exact employer, unit, housing, and daily movement usually do not.</p>
</section>

<h2>Privacy checklist before publishing</h2>
<ul class="signal-list">
  <li>Review profile text for exact workplace and housing information.</li>
  <li>Confirm whether profession and verification badges are visible.</li>
  <li>Turn on coworker or department exclusions when needed.</li>
  <li>Inspect all eight possible profile photos at full size.</li>
  <li>Know how to block, report, download information, and delete the account.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'us-healthcare-video-intros'
    Title = 'Safe Video Introductions for Healthcare Singles'
    Description = 'A step-by-step guide to short video introductions, consent, privacy, scam awareness, room exits, and mutual follow-up after healthcare speed dating.'
    Eyebrow = 'Video introductions / Safety'
    Image = 'us-healthcare-video-intros.jpg'
    Tags = @('Video intro', 'Speed dating', 'Mutual consent')
    Body = @'
<p>A short video introduction can answer a question that photos and text cannot: does conversation feel comfortable enough to continue? It should be an optional bridge between messaging and an in-person date, not a demand for access to someone's home, workplace, or private schedule.</p>

<h2>Define the purpose before joining</h2>
<p>A useful introduction has a clear length and goal. Three to five minutes is enough to confirm that both people can communicate comfortably, understand the basic dating intention, and decide whether to connect again. It is not enough time for credential interrogation, pressure to move off-platform, or an argument about why someone will not reveal a workplace.</p>

<h2>Prepare the camera frame</h2>
<ul class="signal-list">
  <li>Use a neutral personal space rather than a patient-care area.</li>
  <li>Remove badges, mail, calendars, charts, medication labels, and employer information from view.</li>
  <li>Use headphones if other people are nearby.</li>
  <li>Check lighting and camera permissions before entering the room.</li>
  <li>Keep the exit control visible and easy to reach.</li>
</ul>

<h2>Consent is active throughout the call</h2>
<p>Joining a video room is consent to that conversation, not consent to recording, screenshots, explicit requests, or contact outside the app. Either person should be able to end the session immediately. Leaving must close the video connection and update the room state so minutes are not consumed after the interface disappears.</p>
<p>Recording should never be assumed. If a platform supports recording for a specific moderated event, it needs an explicit disclosure and a separate agreement before the camera session begins.</p>

<h2>Use prompts that reveal compatibility safely</h2>
<div class="planner-grid">
  <div><strong>Schedule</strong><span>"What part of your week usually feels most social?"</span></div>
  <div><strong>Recovery</strong><span>"What helps you reset after a demanding day?"</span></div>
  <div><strong>Dating pace</strong><span>"Do you prefer a planned date or something short and spontaneous?"</span></div>
  <div><strong>Privacy</strong><span>"What work details do you prefer to keep private at first?"</span></div>
</div>

<h2>Watch for pressure patterns</h2>
<p>Scammers often try to move a conversation away from the original platform, create urgency, avoid normal verification, or introduce requests for money. The Federal Trade Commission advises people not to send money or gifts to an online love interest they have not met. The FBI also recommends going slowly, asking questions, and being cautious when someone repeatedly avoids meeting.</p>
<p>Read the <a href="https://consumer.ftc.gov/articles/what-know-about-romance-scams" rel="noopener noreferrer">FTC romance scam guidance</a> and the <a href="https://www.fbi.gov/how-we-can-help-you/scams-and-safety/common-frauds-and-scams/romance-scams" rel="noopener noreferrer">FBI romance scam guidance</a>. Report concerning behavior inside the app as well as through the relevant official channel when appropriate.</p>

<h2>End the room cleanly</h2>
<p>A finished call should stop camera and microphone access, disconnect from the room, stop the usage timer, and clear any stale participant status. The interface should confirm that the room was left. If a connection drops, the backend should expire the session rather than showing two people indefinitely.</p>

<h2>Follow up only after mutual interest</h2>
<p>Speed dating works best when each person answers privately. If both choose to reconnect, the app can open messaging or offer a Shift Report icebreaker. If one person declines or does not answer, no connection should be created and neither person's choice should be exposed.</p>

<section class="callout">
  <h2>A respectful closing line</h2>
  <p>"Thanks for meeting me. I am going to use the private follow-up button after the room, so neither of us has to answer on camera."</p>
</section>

<h2>Video introduction checklist</h2>
<ul class="signal-list">
  <li>Confirm camera, microphone, lighting, and the exit button.</li>
  <li>Use a background that protects work and home details.</li>
  <li>Do not record or capture the screen without explicit permission.</li>
  <li>Leave when conversation becomes pressuring, explicit, or financially focused.</li>
  <li>Use private mutual follow-up instead of demanding an immediate answer.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'us-travel-nurse-dating'
    Title = 'Travel Clinician Dating Across Assignments'
    Description = 'A guide for travel nurses and contract clinicians navigating assignment dates, time zones, location privacy, dating intentions, and continuity between cities.'
    Eyebrow = 'Travel clinicians / Assignments'
    Image = 'us-travel-nurse-dating.jpg'
    Tags = @('Travel assignments', 'Time zones', 'Dating intentions')
    Body = @'
<p>Travel work creates a dating question that local profiles rarely answer: is this connection meant for the current assignment, the next city, or a relationship that can continue across both? Clarity about timing is kinder than pretending the departure date does not exist.</p>

<h2>Show the assignment window without exposing housing</h2>
<p>A profile can display a city and broad assignment month range. It should not reveal an exact hospital, hotel, apartment complex, parking routine, or travel itinerary. Location precision should increase only when a trusted plan requires it.</p>
<p>People between contracts can use a "flexible" location state instead of repeatedly changing a hometown. The profile should distinguish a permanent base, current city, and next confirmed assignment when the user chooses to share them.</p>

<h2>Name the kind of continuity you want</h2>
<div class="planner-grid">
  <div><strong>Local during assignment</strong><span>Meet in the current city without promising relocation or long-distance plans.</span></div>
  <div><strong>Open to long distance</strong><span>Continue after departure if communication and travel expectations work for both people.</span></div>
  <div><strong>Looking for a home base</strong><span>Date with the possibility of settling or choosing future assignments differently.</span></div>
  <div><strong>Friendship first</strong><span>Build community in a new city without treating every introduction as a relationship decision.</span></div>
</div>

<h2>Match time zones before matching calendars</h2>
<p>A three-hour time difference can matter more than physical distance when one person works nights. Profiles should display a general time zone and preferred communication windows. Before scheduling video, repeat the time in both zones and confirm whether it is before or after a shift.</p>

<h2>Plan dates that belong to the city, not the facility</h2>
<p>Public places with predictable hours are easier for a first meeting. Choose a museum, market, coffee shop, walking route, or casual meal that does not require either person to reveal housing. Travel clinicians may not know the neighborhood well, so the local person should offer two or three options rather than insisting on a private pickup.</p>
<ul class="signal-list">
  <li>Meet in public and arrange separate transportation.</li>
  <li>Tell a trusted person where the meeting is taking place.</li>
  <li>Do not use employer access, staff areas, or a clinical campus as a date location.</li>
  <li>Keep expensive tickets for later, after reliability is established.</li>
</ul>

<h2>Discuss the departure before it becomes a crisis</h2>
<p>The conversation does not need to happen in the first message, but it should happen before expectations become serious. Ask whether the assignment is likely to extend, how often either person can travel, and what communication rhythm would be realistic between visits. An honest "I do not know yet" is useful when it includes a date for revisiting the question.</p>

<h2>Keep verification separate from employer access</h2>
<p>Travel clinicians can be verified without posting agency contracts, license documents, or facility details publicly. An agency or professional badge should communicate only the approved status and category. Private documents should not become profile photos or chat attachments.</p>

<h2>Build a city support layer</h2>
<p>Travel dating feels less isolating when the product also supports non-dating community. City hubs, coffee meetups, wellness check-ins, and local Nurse Hub resources give users a reason to participate even when a romantic match is not immediate. Community activity should still follow moderation and privacy rules.</p>

<section class="callout">
  <h2>A clear assignment line</h2>
  <p>"I am in Phoenix through October and open to continuing after the assignment if the connection is right. I keep my facility and housing private until trust is established."</p>
</section>

<h2>Travel profile checklist</h2>
<ul class="signal-list">
  <li>Use city and month range instead of exact facility and housing.</li>
  <li>Select local, long-distance, home-base, or friendship-first intentions.</li>
  <li>Show time zone and broad availability.</li>
  <li>Use separate transportation for early meetings.</li>
  <li>Revisit the plan before an assignment ends.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'us-nursing-student-dating'
    Title = 'Dating During Nursing School: Time, Privacy, and Boundaries'
    Description = 'A nursing student guide to dating around clinical rotations, exams, role badges, professional boundaries, safety, and realistic communication.'
    Eyebrow = 'Nursing students / Boundaries'
    Image = 'us-nursing-student-dating.jpg'
    Tags = @('Nursing school', 'Clinical rotations', 'Student privacy')
    Body = @'
<p>Nursing school can make a free evening look available when it is actually reserved for preparation, care plans, commuting, or sleep. A student-friendly dating profile should communicate the season of life honestly without turning school, clinical placement, or patients into public content.</p>

<h2>Use a semester view instead of a normal week</h2>
<p>Availability changes around exams, skills checkoffs, and rotations. Identify three kinds of weeks: regular coursework, high-pressure assessment weeks, and clinical-heavy weeks. A match does not need the full academic calendar, but they should know whether plans usually need several days of notice.</p>
<div class="planner-grid">
  <div><strong>Regular week</strong><span>Short dates and planned calls may fit between class and study blocks.</span></div>
  <div><strong>Exam week</strong><span>Use low-pressure messages and schedule the next plan after the assessment.</span></div>
  <div><strong>Clinical week</strong><span>Expect early mornings, commuting, preparation, and reduced reply speed.</span></div>
  <div><strong>Break period</strong><span>Good time for a longer date, travel, or a relationship check-in.</span></div>
</div>

<h2>Make the student badge accurate</h2>
<p>"Nursing Student Verified" should mean that a private review confirmed current student status using the app's documented process. It should not present the person as a licensed nurse. The badge can help users understand the role while keeping student IDs, school documents, and placement details private.</p>

<h2>Protect clinical information</h2>
<p>Do not post patient stories, room photos, clinical paperwork, or details that could identify a person or facility event. Removing a name does not automatically make a story safe to publish. The NCSBN provides specific resources for nurses and students on responsible social media use and professional boundaries.</p>
<p>Review the <a href="https://www.ncsbn.org/brochures-and-posters/nurses-guide-to-the-use-of-socialmedia" rel="noopener noreferrer">NCSBN social media guide</a> and the <a href="https://www.ncsbn.org/nursing-regulation/practice/professional-boundaries.page" rel="noopener noreferrer">NCSBN professional boundaries resources</a>. School policies and the rules in the student's jurisdiction may add requirements.</p>

<h2>Choose dates that support the goal</h2>
<p>A study date is not always a good first date because one person may expect attention while the other needs to concentrate. For early meetings, choose a defined activity with a clear end time. Coffee after class, a weekend walk, a quick meal, or a short video introduction can be easier than combining coursework and romance immediately.</p>

<h2>Communicate capacity without apologizing</h2>
<p>A useful message explains the constraint and offers an alternative: "I have a checkoff Thursday, so I will be quiet until then. Could we talk Friday evening?" That is clearer than disappearing or sending repeated apologies. The other person can then decide whether the pace works for them.</p>

<h2>Keep school and dating networks separate when needed</h2>
<p>Some students do not want classmates, instructors, or people at the same clinical placement to see their profile. Discovery controls should support broad school privacy, coworker exclusions, and blocking without requiring public disclosure of why the boundary exists.</p>
<ul class="signal-list">
  <li>Do not publish a clinical unit or rotation schedule.</li>
  <li>Use a broad city rather than a residence hall or campus building.</li>
  <li>Keep faculty, preceptor, and patient information out of chats.</li>
  <li>Report profiles that misrepresent licensure or request private documents.</li>
</ul>

<section class="callout">
  <h2>A realistic student profile line</h2>
  <p>"Nursing student with early clinical mornings. I plan dates ahead, go quiet before exams, and prefer a short first meetup or video intro."</p>
</section>

<h2>Student dating checklist</h2>
<ul class="signal-list">
  <li>Show student status accurately and optionally.</li>
  <li>Set broad availability around clinical and exam periods.</li>
  <li>Keep school documents and placement information private.</li>
  <li>Use separate study time and date time until expectations are clear.</li>
  <li>Choose safety and reporting tools before moving off-platform.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'us-allied-healthcare-dating'
    Title = 'Dating for Dental and Allied Healthcare Professionals'
    Description = 'A healthcare dating guide for dental professionals, imaging staff, therapists, laboratory teams, technicians, assistants, and other allied roles.'
    Eyebrow = 'Dental and allied health / Inclusion'
    Image = 'us-allied-healthcare-dating.jpg'
    Tags = @('Dental professionals', 'Allied health', 'Role badges')
    Body = @'
<p>Healthcare dating should not treat every professional as a nurse or physician. Dental teams, imaging staff, respiratory care, rehabilitation, laboratory services, pharmacy, surgical support, emergency services, behavioral health, administration, and many other roles have schedules and responsibilities that deserve accurate representation.</p>

<h2>Let people choose a precise role</h2>
<p>A profession selector should include common titles and an "other healthcare role" path that can be reviewed without forcing the wrong label. Public badges should use the role the person selected and verified, while still allowing someone to hide the badge before account creation or later in settings.</p>
<div class="planner-grid">
  <div><strong>Dental care</strong><span>Dentists, hygienists, assistants, laboratory technicians, office teams, and dental students.</span></div>
  <div><strong>Diagnostic services</strong><span>Radiologic, ultrasound, MRI, CT, nuclear medicine, and laboratory professionals.</span></div>
  <div><strong>Therapy and rehabilitation</strong><span>Respiratory, physical, occupational, speech, behavioral, and rehabilitation roles.</span></div>
  <div><strong>Clinical support</strong><span>Medical assistants, surgical technologists, pharmacy staff, technicians, transport, and care coordination.</span></div>
</div>

<h2>Match on work rhythm, not prestige</h2>
<p>A dental hygienist with weekday clinic hours may have a very different routine from a respiratory therapist rotating through nights. A laboratory professional may work behind the scenes on a strict shift, while a mobile imaging clinician travels between locations. Compatibility depends on the actual pattern, not a hierarchy of titles.</p>
<p>Profiles should ask about shift type, weekend frequency, call responsibilities, travel, and preferred dating windows. Those fields make cross-role matching more useful without asking people to compare salaries, credentials, or status.</p>

<h2>Use language that respects scope</h2>
<p>Do not describe every healthcare worker as a nurse. Do not let a general badge imply licensure that was not reviewed. Accurate labels help members feel included and reduce misrepresentation. The product should also support students, trainees, and nonclinical hospital staff with clearly distinct categories.</p>

<h2>Apply the same privacy standards everywhere</h2>
<p>Dental charts, imaging screens, laboratory labels, appointment schedules, and patient conversations can contain sensitive information just as hospital records do. Profile images should be taken away from active work areas, and chats should never use a patient case as entertainment or proof of expertise.</p>
<p>The U.S. Department of Health and Human Services provides authoritative information about <a href="https://www.hhs.gov/hipaa/for-professionals/privacy/index.html" rel="noopener noreferrer">health information privacy</a>. Members should also follow employer policies, professional standards, and the rules that apply in their location.</p>

<h2>Design dates around the real schedule</h2>
<ul class="signal-list">
  <li>Clinic-hour professionals may prefer evening or weekend plans booked in advance.</li>
  <li>Hospital and emergency roles may need flexible cancellation policies.</li>
  <li>Mobile and contract roles may need city and time-zone matching.</li>
  <li>Students and trainees may need shorter dates around examinations.</li>
  <li>On-call professionals should choose plans that can pause without conflict.</li>
</ul>

<h2>Build community beyond dating</h2>
<p>A Nurse Hub can serve the broader healthcare community with shift-wellness resources, professional privacy reminders, staffing and college information, travel city guides, and moderated discussion spaces. Partner content should be labeled clearly and should not be disguised advertising.</p>

<section class="callout">
  <h2>An inclusive profile example</h2>
  <p>"Dental hygienist, weekday clinic schedule, verified role visible. I prefer planned evening dates and keep my workplace private."</p>
</section>

<h2>Allied-health profile checklist</h2>
<ul class="signal-list">
  <li>Select the most accurate profession and badge visibility.</li>
  <li>Add shift, call, travel, and weekend information.</li>
  <li>Keep patient and employer data outside the profile.</li>
  <li>Choose workplace and coworker discovery controls.</li>
  <li>Report role impersonation or requests for credential documents.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'healthcare-dating-safety-guide'
    Title = 'Healthcare Dating Safety Guide'
    Description = 'A practical safety guide for Nurse Singles covering profile checks, video introductions, romance scams, reporting, blocking, public meetings, and child safety.'
    Eyebrow = 'Safety center / Adult dating'
    Image = 'us-healthcare-privacy-dating.jpg'
    Tags = @('Dating safety', 'Scam prevention', 'Reporting')
    Body = @'
<p>Safety is a sequence of decisions, not a badge that guarantees another person's behavior. Verification, photo moderation, reporting, blocking, and video introductions can reduce uncertainty, but members still need clear ways to slow down, leave, and ask for help.</p>

<h2>Check the profile before starting a conversation</h2>
<p>Look for internal consistency between role, age, location, photos, and written details. A verification badge should say exactly what was reviewed. It should not replace judgment or imply that the app guarantees identity, employment, criminal history, or future conduct unless those checks actually occurred.</p>

<h2>Keep early communication inside the app</h2>
<p>Moving immediately to private messaging removes some platform reporting and moderation context. Take time to understand the person's communication pattern. Pressure to share a phone number, exact workplace, home address, financial information, identification documents, or explicit images is a reason to pause.</p>

<h2>Recognize common romance scam patterns</h2>
<ul class="signal-list">
  <li>The relationship becomes unusually intense before normal trust develops.</li>
  <li>The person repeatedly avoids video or in-person plans while giving changing explanations.</li>
  <li>An emergency introduces requests for money, gift cards, cryptocurrency, banking access, or account transfers.</li>
  <li>The person asks for private photos or information that could be used for pressure or extortion.</li>
  <li>The profile story, photos, location, and availability do not remain consistent.</li>
</ul>
<p>The FTC advises people never to send money or gifts to an online love interest they have not met. The FBI recommends going slowly, asking questions, and being careful about details posted publicly. Review the <a href="https://consumer.ftc.gov/articles/what-know-about-romance-scams" rel="noopener noreferrer">FTC guidance</a> and <a href="https://www.fbi.gov/how-we-can-help-you/scams-and-safety/common-frauds-and-scams/romance-scams" rel="noopener noreferrer">FBI guidance</a>.</p>

<h2>Use video as one signal, not proof</h2>
<p>A short video introduction can confirm that live conversation is possible, but it does not prove every claim. Use a neutral background, do not record without consent, and leave if the call becomes explicit, threatening, manipulative, or financially focused.</p>

<h2>Plan the first in-person meeting</h2>
<div class="planner-grid">
  <div><strong>Public location</strong><span>Choose a staffed place with predictable hours and an easy exit.</span></div>
  <div><strong>Separate transportation</strong><span>Do not depend on a new match for a ride home.</span></div>
  <div><strong>Trusted contact</strong><span>Tell someone where you are going and when you expect to check in.</span></div>
  <div><strong>Short first plan</strong><span>A defined end time makes it easier to leave without negotiation.</span></div>
</div>

<h2>Block and report for different reasons</h2>
<p>Blocking protects the reporting member from further contact. Reporting sends information to the moderation team for review. A person may need both. Reports should support categories such as impersonation, harassment, explicit content, financial solicitation, underage user, patient-information exposure, threats, and offline safety concerns.</p>
<p>Moderation should preserve the information needed for review without exposing the reporter to the reported person. Serious or imminent danger should be directed to local emergency services. Financial fraud can also be reported to the appropriate government agency.</p>

<h2>Child safety is non-negotiable</h2>
<p>Nurse Singles is for adults. Suspected underage accounts, grooming behavior, child sexual abuse material, or attempts to sexualize minors require immediate restriction, preservation of required evidence, and reporting through the processes required by applicable law. Members can review the public <a href="/child-safety-standards">Child Safety Standards</a> and use in-app reporting.</p>

<h2>Protect professional information</h2>
<p>Do not post patient details, license documents, employee IDs, internal schedules, facility incidents, or private work systems. A healthcare connection should be based on lifestyle and values, not access to clinical information.</p>

<section class="callout">
  <h2>Stop when the pace stops feeling voluntary</h2>
  <p>You do not owe another member an explanation for blocking, leaving a call, declining a match, or refusing to share private information.</p>
</section>

<h2>Safety checklist</h2>
<ul class="signal-list">
  <li>Keep money, identity documents, and account access private.</li>
  <li>Use the app's video, block, and report tools.</li>
  <li>Meet publicly with separate transportation.</li>
  <li>Tell a trusted person about the first meeting.</li>
  <li>Report underage accounts and child safety concerns immediately.</li>
</ul>
'@
  },
  [pscustomobject]@{
    Slug = 'shift-friendly-first-date-planner'
    Title = 'Shift-Friendly First Date Planner'
    Description = 'A practical first-date planner for nurses and healthcare workers with 30-, 60-, and 90-minute options around day, night, rotating, and on-call schedules.'
    Eyebrow = 'Planning tool / First dates'
    Image = 'us-night-shift-nurse-dating.jpg'
    Tags = @('Date planning', 'Shift overlap', 'Low-pressure plans')
    Body = @'
<p>A good first date does not need to occupy an entire evening. For healthcare workers, the most respectful plan often has a clear start, a clear end, and enough flexibility to survive overtime or a changed rotation.</p>

<h2>Step 1: Find the real overlap</h2>
<p>Compare awake and rested time, not only clock availability. Someone leaving a twelve-hour shift may technically be free but not ready to drive across town or hold a long conversation. Mark sleep, commute, preparation, and recovery before choosing the overlap.</p>

<h2>Step 2: Pick a duration</h2>
<div class="planner-grid">
  <div><strong>30 minutes</strong><span>Coffee, tea, a hospital-district walk away from the facility, or a short video introduction.</span></div>
  <div><strong>60 minutes</strong><span>Casual breakfast, bookstore visit, lunch, dessert, or one focused activity.</span></div>
  <div><strong>90 minutes</strong><span>Early dinner, museum section, market visit, mini golf, or a relaxed neighborhood walk.</span></div>
  <div><strong>Later date</strong><span>Concerts, day trips, cooking, and longer events after reliability and preferences are known.</span></div>
</div>

<h2>Step 3: Match the plan to the shift</h2>
<ul class="signal-list">
  <li><strong>Day shift:</strong> choose a nearby early evening plan with an end time that protects the next morning.</li>
  <li><strong>Night shift:</strong> consider breakfast after the final shift or afternoon coffee after a recovery sleep.</li>
  <li><strong>Rotating shift:</strong> schedule within the current rotation and confirm the day before.</li>
  <li><strong>On call:</strong> choose a refundable or no-ticket activity and explain the interruption possibility.</li>
  <li><strong>Student clinicals:</strong> avoid the night before an early rotation or major assessment.</li>
</ul>

<h2>Step 4: Choose the location safely</h2>
<p>The location should be public, easy to leave, and reachable without sharing a home address. Each person should control their own transportation. A first meeting at an exact workplace can create privacy and professional-boundary problems, so choose a neutral location instead.</p>

<h2>Step 5: Make the invitation specific</h2>
<p>"Want to meet sometime?" creates more work. A shift-friendly invitation offers a small number of realistic choices: "I am free Tuesday from 4:30 to 6 or Saturday morning. Would coffee for about an hour work?" The other person can answer without rebuilding the plan.</p>

<h2>Step 6: Agree on the cancellation rule</h2>
<p>Healthcare work can change suddenly, but repeated last-minute cancellations still affect trust. Agree that either person can cancel for work or safety, then require a new proposed time when they want to continue. That separates unavoidable schedule changes from a lack of effort.</p>

<section class="callout">
  <h2>A complete first-date invitation</h2>
  <p>"I have a real day off Sunday. Would you like coffee at the public market from 11 to noon? We can each get there separately, and no pressure to extend it if either of us is tired."</p>
</section>

<h2>Low-cost plans that still feel intentional</h2>
<p>A thoughtful date is defined by attention, not price. Try a coffee tasting, public garden, library exhibit, free museum hour, farmers market, neighborhood photo walk, board-game cafe, or one shared dessert. Confirm accessibility, dietary needs, parking, and opening hours before suggesting the activity.</p>

<h2>When video is the better first plan</h2>
<p>Use a short video introduction when distance, time zones, rotating shifts, mobility, or uncertainty makes an in-person meeting difficult. Keep it optional, use a neutral background, and rely on mutual follow-up rather than asking for an answer on camera.</p>

<h2>First-date planner checklist</h2>
<ul class="signal-list">
  <li>Choose rested overlap rather than calendar overlap.</li>
  <li>Set a 30-, 60-, or 90-minute duration.</li>
  <li>Use a public location and separate transportation.</li>
  <li>Offer two specific time choices.</li>
  <li>Confirm the cancellation and rescheduling expectation.</li>
  <li>Keep work, patient, and home details private.</li>
</ul>
'@
  }
)

$pageTemplate = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{TITLE}} | Nurse Singles</title>
  <meta name="description" content="{{DESCRIPTION}}">
  <meta name="google-adsense-account" content="{{PUBLISHER_ID}}">
  <link rel="canonical" href="https://nurse-singles.com/blog/{{SLUG}}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{{TITLE}}">
  <meta property="og:description" content="{{DESCRIPTION}}">
  <meta property="og:image" content="https://nurse-singles.com/blog/images/{{IMAGE}}">
  <meta property="og:url" content="https://nurse-singles.com/blog/{{SLUG}}">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="stylesheet" href="/blog/blog.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={{PUBLISHER_ID}}" crossorigin="anonymous"></script>
  <script type="application/ld+json">{{SCHEMA}}</script>
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
      <div class="eyebrow">{{EYEBROW}}</div>
      <h1>{{TITLE}}</h1>
      <p class="dek">{{DESCRIPTION}}</p>
      <div class="byline">
        <span>By Nurse Singles Editorial Team</span>
        <span>Published and reviewed July 22, 2026</span>
      </div>
      <div class="meta-row">{{CHIPS}}</div>
      <img class="hero-image" src="/blog/images/{{IMAGE}}" alt="{{TITLE}}" loading="eager">
      {{BODY}}
      <section class="editorial-note">
        <h2>Editorial approach</h2>
        <p>This guide provides practical dating and privacy education for adults in healthcare. It is not medical, legal, employment, or licensing advice. Official sources are linked where a regulatory or scam-prevention topic is discussed. Corrections can be sent through the <a href="/contact">Nurse Singles contact page</a>.</p>
      </section>
      <section class="cta" aria-label="Try Nurse Singles">
        <h2>Meet around real healthcare schedules</h2>
        <p>Create a profile with role, shift, privacy, and dating-intention controls.</p>
        <a href="/welcome">Open Nurse Singles</a>
        <a href="/blog/">Explore Nurse Hub</a>
      </section>
    </article>
  </main>
  <footer class="footer">Nurse Singles is an adult dating and community product. Do not share patient information.</footer>
</body>
</html>
'@

foreach ($article in $articles) {
  $schema = [ordered]@{
    '@context' = 'https://schema.org'
    '@type' = 'Article'
    headline = $article.Title
    description = $article.Description
    image = "https://nurse-singles.com/blog/images/$($article.Image)"
    datePublished = $published
    dateModified = $published
    author = [ordered]@{
      '@type' = 'Organization'
      name = 'Nurse Singles Editorial Team'
      url = 'https://nurse-singles.com/about'
    }
    publisher = [ordered]@{
      '@type' = 'Organization'
      name = 'Nurse Singles'
      url = 'https://nurse-singles.com'
    }
    mainEntityOfPage = "https://nurse-singles.com/blog/$($article.Slug)"
  } | ConvertTo-Json -Depth 6 -Compress

  $chips = ($article.Tags | ForEach-Object {
    "<span class=`"chip`">$_</span>"
  }) -join "`n        "

  $page = $pageTemplate.Replace('{{TITLE}}', $article.Title)
  $page = $page.Replace('{{DESCRIPTION}}', $article.Description)
  $page = $page.Replace('{{PUBLISHER_ID}}', $publisherId)
  $page = $page.Replace('{{SLUG}}', $article.Slug)
  $page = $page.Replace('{{IMAGE}}', $article.Image)
  $page = $page.Replace('{{SCHEMA}}', $schema)
  $page = $page.Replace('{{EYEBROW}}', $article.Eyebrow)
  $page = $page.Replace('{{CHIPS}}', $chips)
  $page = $page.Replace('{{BODY}}', $article.Body.Trim())

  Set-Content -LiteralPath (Join-Path $outputRoot "$($article.Slug).html") -Value $page -Encoding UTF8
}

$cards = ($articles | ForEach-Object {
  @"
      <article class="card">
        <img src="/blog/images/$($_.Image)" alt="$($_.Title)" loading="lazy">
        <div class="card-body">
          <div class="eyebrow">$($_.Eyebrow)</div>
          <h2><a href="/blog/$($_.Slug)">$($_.Title)</a></h2>
          <p>$($_.Description)</p>
        </div>
      </article>
"@
}) -join "`n"

$hubSchema = [ordered]@{
  '@context' = 'https://schema.org'
  '@type' = 'CollectionPage'
  name = 'Nurse Hub'
  description = 'Original practical guides for healthcare dating, schedules, privacy, video introductions, students, travel clinicians, dental teams, allied health professionals, and safety.'
  url = 'https://nurse-singles.com/blog/'
  publisher = [ordered]@{
    '@type' = 'Organization'
    name = 'Nurse Singles'
    url = 'https://nurse-singles.com'
  }
} | ConvertTo-Json -Depth 5 -Compress

$hubPage = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Nurse Hub | Practical Healthcare Dating Guides</title>
  <meta name="description" content="Original practical guides for healthcare dating, night shift schedules, workplace privacy, video introductions, students, travel clinicians, dental teams, allied health, and safety.">
  <meta name="google-adsense-account" content="$publisherId">
  <link rel="canonical" href="https://nurse-singles.com/blog/">
  <meta property="og:type" content="website">
  <meta property="og:title" content="Nurse Hub | Nurse Singles">
  <meta property="og:description" content="Practical, reviewed guides for adults dating around real healthcare schedules and professional boundaries.">
  <meta property="og:url" content="https://nurse-singles.com/blog/">
  <meta property="og:image" content="https://nurse-singles.com/blog/images/us-night-shift-nurse-dating.jpg">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="stylesheet" href="/blog/blog.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$publisherId" crossorigin="anonymous"></script>
  <script type="application/ld+json">$hubSchema</script>
</head>
<body>
  <header class="topbar">
    <nav class="nav" aria-label="Main navigation">
      <a class="brand" href="/"><span class="brand-mark">NS</span><strong>Nurse Singles</strong></a>
      <div class="nav-links">
        <a href="/blog/" aria-current="page">Nurse Hub</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
        <a href="/privacy">Privacy</a>
        <a href="/child-safety-standards">Safety</a>
        <a href="/welcome">Open App</a>
      </div>
    </nav>
  </header>
  <main class="wrap">
    <section class="hub-intro">
      <div class="eyebrow">Nurse Hub editorial library</div>
      <h1>Practical guidance for dating around healthcare life</h1>
      <p>These guides focus on decisions healthcare workers actually face: sleep and shift overlap, workplace privacy, travel assignments, professional role accuracy, safer video introductions, and first-date planning.</p>
      <p>Every indexed guide has a distinct editorial purpose. Nurse Hub does not publish patient stories, clinical advice, copied news, or mass-produced city pages.</p>
    </section>
    <section class="grid" aria-label="Nurse Hub guides">
$cards
    </section>
    <section class="editorial-note hub-note">
      <h2>How Nurse Hub publishes</h2>
      <p>Articles are written for adults, reviewed for healthcare privacy language, and linked to primary sources when discussing professional guidance or scam prevention. Content is educational and does not replace medical, legal, licensing, employment, or safety advice from qualified authorities.</p>
      <p>Questions and corrections are welcome through the <a href="/contact">contact page</a>. Product policies are available in the <a href="/privacy">Privacy Policy</a>, <a href="/terms">Terms</a>, and <a href="/child-safety-standards">Child Safety Standards</a>.</p>
    </section>
  </main>
  <footer class="footer">Nurse Singles is an adult dating and community product for healthcare professionals and students.</footer>
</body>
</html>
"@

Set-Content -LiteralPath (Join-Path $outputRoot 'index.html') -Value $hubPage -Encoding UTF8

$staticUrls = @(
  '/',
  '/about',
  '/contact',
  '/privacy',
  '/terms',
  '/child-safety-standards',
  '/account-deletion',
  '/blog/'
)
$allUrls = @($staticUrls) + @($articles | ForEach-Object { "/blog/$($_.Slug)" })
$urlEntries = ($allUrls | ForEach-Object {
  $priority = if ($_ -eq '/') { '1.0' } elseif ($_ -eq '/blog/') { '0.9' } else { '0.8' }
  @"
  <url>
    <loc>https://nurse-singles.com$_</loc>
    <lastmod>$published</lastmod>
    <changefreq>monthly</changefreq>
    <priority>$priority</priority>
  </url>
"@
}) -join "`n"

$sitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$urlEntries
</urlset>
"@
Set-Content -LiteralPath (Join-Path $PSScriptRoot '..\public\sitemap.xml') -Value $sitemap -Encoding UTF8

Write-Host "Generated $($articles.Count) curated Nurse Hub guides, the hub index, and sitemap."
