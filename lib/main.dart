import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const AdventureGame());
}

class AdventureGame extends StatelessWidget {
  const AdventureGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adventure Quest',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameState {
  int hp = 100;
  int maxHp = 100;
  int plstr = 8;
  int plend = 8;
  int exp = 0;
  int unspentSkp = 8;
  int level = 1;

  List<String> skills = ['Shield Bash', 'Poison Throw', 'Double Slash', 'Burst Strike'];
  List<int> skillDamage = [18, 12, 24, 30];

  void updateStats() {
    maxHp = 1 + (plstr * 2) + (plend * 4);
    hp = maxHp;
  }
}

class Enemy {
  String name;
  int hp=1;
  int maxHp=1;
  int str=1;
  int end=1;
  int exp=1;

  Enemy({
    required this.name,
    required this.str,
    required this.end,
    required this.exp,
  }) {
    this.maxHp = 1 + (str * 2) + (end * 4);
    this.hp = maxHp;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  String currentScreen = 'menu';
  Enemy? currentEnemy;
  String battleMessage = 'What will you do?';
  bool isEnemyTurn = false;
  bool battleEnded = false;
  bool playerWon = false;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.updateStats();
  }

  void startBattle(Enemy enemy) {
    setState(() {
      currentEnemy = enemy;
      currentScreen = 'fight';
      battleMessage = 'A wild ${enemy.name} appears!';
      isEnemyTurn = false;
      battleEnded = false;
      playerWon = false;
    });
  }

  void playerAttack() {
    if (isEnemyTurn || battleEnded || currentEnemy == null) return;

    final damage = max(1, (gameState.plstr * 1.15 - (currentEnemy!.end * 0.1)).toInt());
    currentEnemy!.hp -= damage;

    setState(() {
      battleMessage = 'You attacked for $damage damage!';
      isEnemyTurn = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (currentEnemy!.hp <= 0) {
        endBattle(true);
      } else {
        enemyAttack();
      }
    });
  }

  void playerUseSkill(int skillIndex) {
    if (isEnemyTurn || battleEnded || currentEnemy == null) return;

    final skillName = gameState.skills[skillIndex];
    final damage = gameState.skillDamage[skillIndex];
    final actualDamage = max(1, (damage - (currentEnemy!.end * 0.05)).toInt());
    currentEnemy!.hp -= actualDamage;

    setState(() {
      battleMessage = 'You used $skillName!\nDealt $actualDamage damage!';
      isEnemyTurn = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (currentEnemy!.hp <= 0) {
        endBattle(true);
      } else {
        enemyAttack();
      }
    });
  }

  void enemyAttack() {
    if (currentEnemy == null) return;

    final damage = max(1, (currentEnemy!.str * 1.15 - (gameState.plend * 0.1)).toInt());
    gameState.hp -= damage;

    setState(() {
      battleMessage = '${currentEnemy!.name} attacked for $damage damage!';
      isEnemyTurn = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (gameState.hp <= 0) {
        endBattle(false);
      } else {
        setState(() {
          battleMessage = 'What will you do?';
        });
      }
    });
  }

  void endBattle(bool playerWon) {
    setState(() {
      battleEnded = true;
      this.playerWon = playerWon;
      if (playerWon) {
        gameState.exp += currentEnemy!.exp;
        gameState.level += gameState.exp ~/ 10;
        gameState.updateStats();
        battleMessage = 'Victory! Defeated ${currentEnemy!.name}!\nGained ${currentEnemy!.exp} EXP!';
      } else {
        gameState.hp = gameState.maxHp;
        battleMessage = 'You were defeated!\nReturning to town...';
      }
    });
  }

  void heal() {
    gameState.hp = gameState.maxHp;
    setState(() {});
  }

  void spendSkillPoint(int type) {
    if (gameState.unspentSkp > 0) {
      setState(() {
        if (type == 1) {
          gameState.plend++;
        } else {
          gameState.plstr++;
        }
        gameState.unspentSkp--;
        gameState.updateStats();
      });
    }
  }

  void startQuest(int questType) {
    final random = Random();
    Enemy enemy;

    if (questType == 1) {
      final monType = random.nextInt(3);
      if (monType < 2) {
        enemy = Enemy(name: 'Goblin', str: 8, end: 9, exp: 1);
      } else {
        enemy = Enemy(name: 'Dire Wolf', str: 17, end: 14, exp: 2);
      }
    } else {
      final monType = random.nextInt(10);
      if (monType < 5) {
        enemy = Enemy(name: 'Skeleton', str: 12, end: 9, exp: 1);
      } else if (monType < 8) {
        enemy = Enemy(name: 'Spider', str: 25, end: 4, exp: 2);
      } else {
        enemy = Enemy(name: 'Skeleton Knight', str: 15, end: 20, exp: 3);
      }
    }

    startBattle(enemy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentScreen == 'menu'
          ? buildMenuScreen()
          : buildFightScreen(),
    );
  }

  Widget buildMenuScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple[900]!, Colors.purple[700]!],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'CITY OF AAGON',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level: ${gameState.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'HP: ${gameState.hp}/${gameState.maxHp}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'STR: ${gameState.plstr} | END: ${gameState.plend}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'EXP: ${gameState.exp}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unspent Skill Points: ${gameState.unspentSkp}',
                        style: const TextStyle(
                          color: Colors.lime,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                MenuButton(
                  label: 'Heal',
                  onPressed: () {
                    heal();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fully healed!')),
                    );
                  },
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Patrol the Forest',
                  onPressed: () => startQuest(1),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Clear the Ruins',
                  onPressed: () => startQuest(2),
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Level Up',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setDialogState) => AlertDialog(
                          title: const Text('Spend Skill Points'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Available: ${gameState.unspentSkp}'),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    onPressed: () {
                                      spendSkillPoint(1);
                                      setDialogState(() {});
                                    },
                                    child: const Text('Endurance +1'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      spendSkillPoint(2);
                                      setDialogState(() {});
                                    },
                                    child: const Text('Strength +1'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {});
                              },
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFightScreen() {
    if (currentEnemy == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[800]!, Colors.green[600]!],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Enemy Section
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentEnemy!.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lv${(currentEnemy!.str + currentEnemy!.end) ~/ 2}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'HP: ${currentEnemy!.hp.clamp(0, currentEnemy!.maxHp)}/${currentEnemy!.maxHp}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (currentEnemy!.hp.clamp(0, currentEnemy!.maxHp) / currentEnemy!.maxHp).clamp(0.0, 1.0),
                                  minHeight: 16,
                                  backgroundColor: Colors.grey[700],
                                  valueColor: AlwaysStoppedAnimation(
                                    currentEnemy!.hp < currentEnemy!.maxHp * 0.3 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Battle Message Box
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    battleMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Player Section
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLAYER',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lv${gameState.level}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 16),
                      child: SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HP: ${gameState.hp.clamp(0, gameState.maxHp)}/${gameState.maxHp}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (gameState.hp.clamp(0, gameState.maxHp) / gameState.maxHp).clamp(0.0, 1.0),
                                minHeight: 16,
                                backgroundColor: Colors.grey[700],
                                valueColor: AlwaysStoppedAnimation(
                                  gameState.hp < gameState.maxHp * 0.3 ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons
            if (!battleEnded && gameState.hp > 0 && currentEnemy!.hp > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    FightButton(
                      label: 'ATTACK',
                      onPressed: isEnemyTurn ? null : playerAttack,
                      color: Colors.red,
                    ),
                    FightButton(
                      label: 'SKILL',
                      onPressed: isEnemyTurn ? null : () => _showSkillMenu(),
                      color: Colors.blue,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        currentScreen = 'menu';
                        currentEnemy = null;
                        gameState.hp = gameState.maxHp;
                      });
                    },
                    child: const Text(
                      'RETURN TO TOWN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSkillMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'SELECT A SKILL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...List.generate(
              gameState.skills.length,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      playerUseSkill(index);
                    },
                    child: Text(
                      '${gameState.skills[index]} (${gameState.skillDamage[index]} dmg)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const MenuButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class FightButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const FightButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey : color,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}