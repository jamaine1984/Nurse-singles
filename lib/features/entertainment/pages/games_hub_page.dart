import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';

class GamesHubPage extends StatefulWidget {
  const GamesHubPage({super.key});

  @override
  State<GamesHubPage> createState() => _GamesHubPageState();
}

class _GamesHubPageState extends State<GamesHubPage> {
  _GameType _selectedGame = _GameType.loveLanguage;
  int _questionIndex = 0;
  int _triviaIndex = 0;
  int _triviaScore = 0;
  int _wouldIndex = 0;
  int _rouletteIndex = 0;
  int _breakRoomPoints = 0;
  final List<_BoardEvent> _boardEvents = [];
  final Map<String, int> _scores = {
    'Words': 0,
    'Time': 0,
    'Acts': 0,
    'Gifts': 0,
    'Touch': 0,
  };

  static const _games = [
    _GameInfo(
      type: _GameType.loveLanguage,
      icon: Icons.favorite_border_rounded,
      name: 'Love Language',
      description: 'Learn what kind of care makes a match feel seen.',
      color: Color(0xFF0EA5A3),
    ),
    _GameInfo(
      type: _GameType.nurseTrivia,
      icon: Icons.quiz_rounded,
      name: 'Nurse Trivia',
      description: 'Fast healthcare questions for warm conversation.',
      color: Color(0xFF2563EB),
    ),
    _GameInfo(
      type: _GameType.shiftRoulette,
      icon: Icons.cyclone_rounded,
      name: 'Shift Roulette',
      description: 'Spin for a shift-safe icebreaker.',
      color: Color(0xFFF59E0B),
    ),
    _GameInfo(
      type: _GameType.wouldYouRather,
      icon: Icons.forum_rounded,
      name: 'Would You Rather',
      description: 'Healthcare themed dilemmas to spark replies.',
      color: Color(0xFFDC2626),
    ),
  ];

  static const _loveQuestions = [
    _LoveQuestion(
      prompt: 'After a brutal shift, what would make you feel most cared for?',
      answers: [
        _LoveAnswer('A thoughtful voice note', 'Words'),
        _LoveAnswer('Dinner together with phones away', 'Time'),
        _LoveAnswer('They handle an errand for you', 'Acts'),
      ],
    ),
    _LoveQuestion(
      prompt: 'What kind of first message actually catches your attention?',
      answers: [
        _LoveAnswer('Something specific and encouraging', 'Words'),
        _LoveAnswer('A plan for coffee after shift', 'Time'),
        _LoveAnswer('A small helpful recommendation', 'Acts'),
      ],
    ),
    _LoveQuestion(
      prompt: 'Your ideal speed-date follow-up feels like:',
      answers: [
        _LoveAnswer('Clear words about wanting to reconnect', 'Words'),
        _LoveAnswer('A quick scheduled video intro', 'Time'),
        _LoveAnswer('Remembering your quiet hours', 'Acts'),
      ],
    ),
    _LoveQuestion(
      prompt: 'Which gesture feels most romantic during a busy week?',
      answers: [
        _LoveAnswer('A small coffee or snack surprise', 'Gifts'),
        _LoveAnswer('A calm walk after work', 'Time'),
        _LoveAnswer('A warm hug when you are drained', 'Touch'),
      ],
    ),
    _LoveQuestion(
      prompt: 'What makes a healthcare match feel emotionally safe?',
      answers: [
        _LoveAnswer('Respecting privacy boundaries', 'Acts'),
        _LoveAnswer('Saying what they appreciate directly', 'Words'),
        _LoveAnswer('Showing up consistently', 'Time'),
      ],
    ),
  ];

  static const _trivia = [
    _TriviaQuestion(
      prompt: 'What does HIPAA mainly protect?',
      answers: [
        _TriviaAnswer('Private health information', true),
        _TriviaAnswer('Hospital parking passes', false),
        _TriviaAnswer('Shift differentials', false),
      ],
      note: 'Privacy matters here too. Do not share patient details in chat.',
    ),
    _TriviaQuestion(
      prompt: 'Which shift signal is most useful before a first video intro?',
      answers: [
        _TriviaAnswer('Quiet hours and preferred dating window', true),
        _TriviaAnswer('Favorite scrub color only', false),
        _TriviaAnswer('Exact license number', false),
      ],
      note: 'The safest match details are schedule and boundaries.',
    ),
    _TriviaQuestion(
      prompt: 'What should stay private on a dating profile?',
      answers: [
        _TriviaAnswer('Exact workplace and license numbers', true),
        _TriviaAnswer('General role', false),
        _TriviaAnswer('Preferred shift', false),
      ],
      note:
          'General healthcare badges are useful. Sensitive credentials are not.',
    ),
  ];

  static const _wouldYouRather = [
    _WouldPrompt(
      a: 'Coffee after night shift',
      b: 'Dinner on your next day off',
    ),
    _WouldPrompt(a: 'A funny voice note', b: 'A carefully planned video intro'),
    _WouldPrompt(
      a: 'Date someone in the same specialty',
      b: 'Date someone outside healthcare',
    ),
  ];

  static const _roulettePrompts = [
    'Send a Shift Report: one thing that helps you decompress after work.',
    'Ask: what is your ideal first date after a long shift?',
    'Share a privacy boundary you appreciate in dating.',
    'Ask which hospital-unit superpower they wish they had.',
    'Invite them to a 5-minute video intro during their preferred window.',
  ];

  void _selectGame(_GameInfo game) {
    setState(() => _selectedGame = game.type);
  }

  void _selectLoveAnswer(_LoveAnswer answer) {
    setState(() {
      _scores[answer.category] = (_scores[answer.category] ?? 0) + 1;
      _addBoardEvent('Love Language insight: ${answer.category}', 15);
      if (_questionIndex < _loveQuestions.length - 1) {
        _questionIndex++;
      } else {
        _showLoveResult();
      }
    });
  }

  void _resetLoveGame() {
    setState(() {
      _questionIndex = 0;
      for (final key in _scores.keys) {
        _scores[key] = 0;
      }
    });
  }

  void _showLoveResult() {
    final winner = _scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Love Language Result'),
          content: Text(
            'Your strongest match signal is ${winner.key}. Add this to your next Shift Report to make conversations more personal.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetLoveGame();
              },
              child: const Text('Play Again'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _answerTrivia(_TriviaAnswer answer) {
    final question = _trivia[_triviaIndex];
    setState(() {
      if (answer.correct) _triviaScore++;
      _addBoardEvent(
        answer.correct
            ? 'Nurse Trivia correct answer'
            : 'Nurse Trivia practice',
        answer.correct ? 25 : 8,
      );
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(answer.correct ? 'Correct' : 'Good try'),
        content: Text(question.note),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (_triviaIndex < _trivia.length - 1) {
                  _triviaIndex++;
                } else {
                  _triviaIndex = 0;
                  _triviaScore = 0;
                }
              });
            },
            child: Text(
              _triviaIndex < _trivia.length - 1 ? 'Next Question' : 'Restart',
            ),
          ),
        ],
      ),
    );
  }

  void _spinRoulette() {
    setState(() {
      final next = Random().nextInt(_roulettePrompts.length);
      _rouletteIndex = next == _rouletteIndex
          ? (next + 1) % _roulettePrompts.length
          : next;
      _addBoardEvent('Shift Roulette opener prepared', 12);
    });
  }

  void _chooseWouldPrompt(String choice) {
    setState(() {
      _addBoardEvent('Would You Rather pick: $choice', 10);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Starter'),
        content: Text(
          'Your pick: $choice. Send this as a low-pressure opener and ask why they would choose it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _wouldIndex = (_wouldIndex + 1) % _wouldYouRather.length;
              });
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _addBoardEvent(String label, int points) {
    _breakRoomPoints += points;
    _boardEvents.insert(0, _BoardEvent(label: label, points: points));
    if (_boardEvents.length > 5) {
      _boardEvents.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Games & Fun',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              theme,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
            const SizedBox(height: 20),
            Text(
              'Choose a Game',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return _GameCard(
                      game: game,
                      selected: game.type == _selectedGame,
                      onTap: () => _selectGame(game),
                    )
                    .animate()
                    .fadeIn(
                      duration: 350.ms,
                      delay: Duration(milliseconds: 80 + index * 60),
                    )
                    .slideY(begin: 0.08, end: 0);
              },
            ),
            const SizedBox(height: 18),
            _buildSelectedGame(theme),
            const SizedBox(height: 24),
            _buildLeaderboardSection(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075985), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Break-room games with a purpose',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Four playable prompts built for healthcare dating.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGame(ThemeData theme) {
    switch (_selectedGame) {
      case _GameType.loveLanguage:
        return _buildLoveLanguage(theme);
      case _GameType.nurseTrivia:
        return _buildTrivia(theme);
      case _GameType.shiftRoulette:
        return _buildShiftRoulette(theme);
      case _GameType.wouldYouRather:
        return _buildWouldYouRather(theme);
    }
  }

  Widget _buildLoveLanguage(ThemeData theme) {
    final question = _loveQuestions[_questionIndex];
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.psychology_alt_rounded,
            title: 'Love Language',
            meta: 'Question ${_questionIndex + 1} of ${_loveQuestions.length}',
            color: const Color(0xFF0EA5A3),
          ),
          const SizedBox(height: 16),
          Text(
            question.prompt,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ...question.answers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _selectLoveAnswer(answer),
                  child: Text(answer.label),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scores.entries
                .map(
                  (entry) => Chip(
                    avatar: const Icon(Icons.add_chart_rounded, size: 16),
                    label: Text('${entry.key}: ${entry.value}'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrivia(ThemeData theme) {
    final question = _trivia[_triviaIndex];
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.quiz_rounded,
            title: 'Nurse Trivia',
            meta: 'Score $_triviaScore/${_trivia.length}',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          Text(
            question.prompt,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          ...question.answers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _answerTrivia(answer),
                  child: Text(answer.label),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRoulette(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.cyclone_rounded,
            title: 'Shift Roulette',
            meta: 'Instant opener',
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _roulettePrompts[_rouletteIndex],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _spinRoulette,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Spin Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWouldYouRather(ThemeData theme) {
    final prompt = _wouldYouRather[_wouldIndex];
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.forum_rounded,
            title: 'Would You Rather',
            meta: 'Tap your pick',
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 16),
          _ChoiceButton(
            label: prompt.a,
            color: const Color(0xFFDC2626),
            onTap: () => _chooseWouldPrompt(prompt.a),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: Text('or')),
          ),
          _ChoiceButton(
            label: prompt.b,
            color: const Color(0xFF0EA5A3),
            onTap: () => _chooseWouldPrompt(prompt.b),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.leaderboard, color: AppTheme.softAmber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Break Room Board',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: AppTheme.emerald,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your break-room score',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Points grow as you play, answer, and prepare better openers.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_breakRoomPoints pts',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_boardEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Play any game above to start filling your board.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._boardEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_rounded,
                          color: AppTheme.softAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '+${event.points}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.softAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final _GameInfo game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? game.color.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected ? game.color : game.color.withValues(alpha: 0.16),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(game.icon, color: game.color, size: 30),
            const SizedBox(height: 10),
            Text(
              game.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                game.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 1.25,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              selected ? 'Playing' : 'Open',
              style: GoogleFonts.plusJakartaSans(
                color: game.color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.meta,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Chip(label: Text(meta)),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

enum _GameType { loveLanguage, nurseTrivia, shiftRoulette, wouldYouRather }

class _GameInfo {
  const _GameInfo({
    required this.type,
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
  });

  final _GameType type;
  final IconData icon;
  final String name;
  final String description;
  final Color color;
}

class _LoveQuestion {
  const _LoveQuestion({required this.prompt, required this.answers});

  final String prompt;
  final List<_LoveAnswer> answers;
}

class _LoveAnswer {
  const _LoveAnswer(this.label, this.category);

  final String label;
  final String category;
}

class _TriviaQuestion {
  const _TriviaQuestion({
    required this.prompt,
    required this.answers,
    required this.note,
  });

  final String prompt;
  final List<_TriviaAnswer> answers;
  final String note;
}

class _TriviaAnswer {
  const _TriviaAnswer(this.label, this.correct);

  final String label;
  final bool correct;
}

class _WouldPrompt {
  const _WouldPrompt({required this.a, required this.b});

  final String a;
  final String b;
}

class _BoardEvent {
  const _BoardEvent({required this.label, required this.points});

  final String label;
  final int points;
}
