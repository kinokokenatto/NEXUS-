import javax.sound.sampled.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;
import javax.swing.text.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.net.*;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.time.*;
import java.time.format.*;
import java.util.*;
import java.util.List;
import java.util.concurrent.*;
import java.util.regex.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import javax.imageio.ImageIO;

/**
 * NEXUS SUPER 4.1 - Java Edition
 *
 * A native Java/Swing implementation of the NEXUS SUPER 4.1 HTML application.
 * Requires only JDK 17 or newer.  All personal data is stored locally under
 * ~/.nexus-super41; network access is opt-in for weather and speed tests.
 */
public final class NexusSuper41 extends JFrame {
    private static final String VERSION = "4.1";
    private static final Color BG = new Color(4, 8, 22);
    private static final Color PANEL = new Color(12, 23, 47);
    private static final Color PANEL2 = new Color(17, 34, 66);
    private static final Color CYAN = new Color(75, 218, 255);
    private static final Color TEXT = new Color(232, 244, 255);
    private static final Color MUTED = new Color(160, 183, 211);
    private static final Path DATA_DIR = Path.of(System.getProperty("user.home"), ".nexus-super41");
    private static final Path DATA_FILE = DATA_DIR.resolve("nexus.properties");
    private final Properties data = new Properties();
    private final ExecutorService workers = Executors.newFixedThreadPool(3, r -> {
        Thread t = new Thread(r, "NEXUS-worker"); t.setDaemon(true); return t;
    });
    private Color accent = CYAN;
    private boolean anonymousMode;
    private boolean autoWeather;
    private boolean privacyBlur;
    private boolean screenProtect;
    private boolean developerEnabled;
    private boolean adminEnabled;
    private boolean fastMode;
    private boolean reducedMotion;
    private boolean debugOutline;
    private boolean sleepEnabled;
    private boolean sleepTest;
    private boolean sleepOverlayOpen;
    private LocalTime sleepStart = LocalTime.of(22, 0);
    private LocalTime sleepEnd = LocalTime.of(7, 0);
    private javax.swing.Timer clockTimer;
    private javax.swing.Timer countTimer;
    private javax.swing.Timer stopwatchTimer;
    private long countEndsAt;
    private long stopwatchStartedAt;
    private long stopwatchElapsed;
    private boolean countRunning;
    private boolean stopwatchRunning;
    private Clip audioClip;
    private Path audioFile;
    private long lastWeatherFetch;
    private String currentWeather = "未取得";
    private final DefaultListModel<String> memoModel = new DefaultListModel<>();
    private final DefaultListModel<String> todoModel = new DefaultListModel<>();
    private final DefaultListModel<String> eventModel = new DefaultListModel<>();
    private final DefaultListModel<String> boardModel = new DefaultListModel<>();
    private final Map<Integer, String> memoIds = new HashMap<>();
    private final Map<Integer, String> todoIds = new HashMap<>();
    private final Map<Integer, String> eventIds = new HashMap<>();
    private final Map<Integer, String> boardIds = new HashMap<>();
    private String selectedMemoId = "";
    private String todoDate = LocalDate.now().toString();
    private final JLabel clockLabel = new JLabel("00:00:00", SwingConstants.CENTER);
    private final JLabel dateLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel timerLabel = new JLabel("05:00", SwingConstants.CENTER);
    private final JLabel stopwatchLabel = new JLabel("00:00.00", SwingConstants.CENTER);
    private final JLabel weatherLabel = new JLabel("天気情報は未取得です");
    private final JLabel systemLabel = new JLabel("NEXUSローカルシステム 起動中");
    private JTextArea memoEditor;
    private JTextField memoTitle;
    private JList<String> memoList;
    private JList<String> todoList;
    private JList<String> eventList;
    private JList<String> boardList;
    private JTextArea boardBody;
    private JTextField boardTitle;
    private JComboBox<String> boardType;
    private JTextField todoInput;
    private JTextField eventTitle;
    private JTextField eventDateTime;
    private JComboBox<String> prefectureBox;
    private JTextArea weatherDetails;
    private JCheckBox autoWeatherBox;
    private JCheckBox anonymousBox;
    private JCheckBox screenProtectBox;
    private JCheckBox privacyBlurBox;
    private JTextArea developerOutput;
    private JTextArea codeInput;
    private JTextArea codeOutput;
    private JTextArea workspaceCode;
    private JTextArea languageOutput;
    private JTextArea translationInput;
    private JTextArea translationOutput;
    private JTextField assistantInput;
    private JLabel assistantReply;
    private DrawPanel drawPanel;

    private static final String[] PREFECTURES = {
        "北海道","青森県","岩手県","宮城県","秋田県","山形県","福島県","茨城県","栃木県","群馬県",
        "埼玉県","千葉県","東京都","神奈川県","新潟県","富山県","石川県","福井県","山梨県","長野県",
        "岐阜県","静岡県","愛知県","三重県","滋賀県","京都府","大阪府","兵庫県","奈良県","和歌山県",
        "鳥取県","島根県","岡山県","広島県","山口県","徳島県","香川県","愛媛県","高知県","福岡県",
        "佐賀県","長崎県","熊本県","大分県","宮崎県","鹿児島県","沖縄県"
    };
    private static final double[][] PREF_COORDS = {
        {43.06,141.35},{40.82,140.74},{39.70,141.15},{38.27,140.87},{39.72,140.10},{38.24,140.36},{37.75,140.47},{36.34,140.45},{36.57,139.88},{36.39,139.06},
        {35.86,139.65},{35.61,140.12},{35.68,139.69},{35.45,139.64},{37.90,139.02},{36.70,137.21},{36.59,136.63},{36.06,136.22},{35.66,138.57},{36.65,138.18},
        {35.39,136.72},{34.98,138.38},{35.18,136.91},{34.73,136.51},{35.00,135.87},{35.02,135.76},{34.69,135.50},{34.69,135.18},{34.69,135.80},{34.23,135.17},
        {35.50,134.24},{35.47,133.05},{34.66,133.93},{34.40,132.46},{34.19,131.47},{34.07,134.56},{34.34,134.04},{33.84,132.77},{33.56,133.53},{33.59,130.40},
        {33.25,130.30},{32.75,129.87},{32.79,130.74},{33.24,131.61},{31.91,131.42},{31.56,130.56},{26.21,127.68}
    };

    public NexusSuper41() {
        super("NEXUS SUPER " + VERSION + " — Java Edition");
        loadData();
        loadSettings();
        configureLookAndFeel();
        buildUi();
        startClocks();
        startSleepMonitor();
        setDefaultCloseOperation(WindowConstants.DO_NOTHING_ON_CLOSE);
        addWindowListener(new WindowAdapter() {
            @Override public void windowClosing(WindowEvent e) { shutdown(); }
            @Override public void windowDeactivated(WindowEvent e) {
                if (privacyBlur) setTitle("NEXUS SUPER " + VERSION + " — プライバシー保護中");
            }
            @Override public void windowActivated(WindowEvent e) {
                setTitle("NEXUS SUPER " + VERSION + " — Java Edition");
            }
        });
        setMinimumSize(new Dimension(940, 680));
        setSize(1380, 900);
        setLocationRelativeTo(null);
    }

    private void configureLookAndFeel() {
        try { UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); } catch (Exception ignored) { }
        Font f = new Font("Noto Sans CJK JP", Font.PLAIN, 13);
        for (Object k : UIManager.getLookAndFeelDefaults().keySet()) {
            if (k.toString().toLowerCase(Locale.ROOT).contains("font")) UIManager.put(k, f);
        }
    }

    private void loadData() {
        try {
            Files.createDirectories(DATA_DIR);
            if (Files.exists(DATA_FILE)) try (InputStream in = Files.newInputStream(DATA_FILE)) { data.load(in); }
        } catch (IOException ex) { JOptionPane.showMessageDialog(null, "ローカルデータを読み込めませんでした: " + ex.getMessage()); }
    }
    private synchronized void saveData() {
        try {
            Files.createDirectories(DATA_DIR);
            try (OutputStream out = Files.newOutputStream(DATA_FILE)) {
                data.store(out, "NEXUS SUPER 4.1 local data — UTF-8 properties");
            }
        } catch (IOException ex) { showError("保存に失敗しました", ex); }
    }
    private String get(String key, String fallback) { return data.getProperty(key, fallback); }
    private void put(String key, String value) { data.setProperty(key, value == null ? "" : value); saveData(); }
    private boolean bool(String key, boolean fallback) { return Boolean.parseBoolean(get(key, Boolean.toString(fallback))); }
    private void putBool(String key, boolean value) { put(key, Boolean.toString(value)); }

    private String encode(String s) { return Base64.getUrlEncoder().withoutPadding().encodeToString(s.getBytes(StandardCharsets.UTF_8)); }
    private String decode(String s) { try { return new String(Base64.getUrlDecoder().decode(s), StandardCharsets.UTF_8); } catch (Exception e) { return ""; } }
    private List<String[]> readRows(String prefix, int fields) {
        List<String[]> out = new ArrayList<>(); int n;
        try { n = Math.max(0, Math.min(5000, Integer.parseInt(get(prefix + ".count", "0")))); } catch (Exception e) { n = 0; }
        for (int i=0;i<n;i++) {
            String[] row = new String[fields]; boolean valid = true;
            for (int j=0;j<fields;j++) { String v=data.getProperty(prefix+"."+i+"."+j); if(v==null){valid=false;break;} row[j]=decode(v); }
            if(valid) out.add(row);
        }
        return out;
    }
    private void writeRows(String prefix, List<String[]> rows) {
        String old = get(prefix + ".count", "0");
        int oldN=0; try{oldN=Integer.parseInt(old);}catch(Exception ignored){}
        for(int i=0;i<oldN;i++) for(int j=0;j<12;j++) data.remove(prefix+"."+i+"."+j);
        data.setProperty(prefix+".count", Integer.toString(rows.size()));
        for(int i=0;i<rows.size();i++) for(int j=0;j<rows.get(i).length;j++) data.setProperty(prefix+"."+i+"."+j,encode(rows.get(i)[j]));
        saveData();
    }

    private void loadSettings() {
        try { accent = Color.decode(get("setting.accent", "#4bd6ff")); } catch (Exception e) { accent = CYAN; }
        autoWeather = bool("setting.autoWeather", false);
        anonymousMode = bool("setting.anonymous", false);
        privacyBlur = bool("setting.privacyBlur", false);
        screenProtect = bool("setting.screenProtect", false);
        developerEnabled = bool("setting.developer", false);
        fastMode = bool("setting.fast", false);
        reducedMotion = bool("setting.reducedMotion", false);
        debugOutline = bool("setting.debugOutline", false);
        sleepEnabled = bool("setting.sleepEnabled", false);
        try { sleepStart = LocalTime.parse(get("setting.sleepStart", "22:00")); } catch (Exception ignored) { }
        try { sleepEnd = LocalTime.parse(get("setting.sleepEnd", "07:00")); } catch (Exception ignored) { }
    }

    private void buildUi() {
        setLayout(new BorderLayout());
        JPanel root = new NebulaPanel(); root.setLayout(new BorderLayout(10,10)); root.setBorder(new EmptyBorder(12,14,12,14));
        JPanel top = new JPanel(new BorderLayout(8,8)); top.setOpaque(false);
        JLabel logo = new JLabel("✦ N E X U S   S U P E R   " + VERSION); logo.setForeground(accent); logo.setFont(logo.getFont().deriveFont(Font.BOLD,22f));
        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT,5,0)); actions.setOpaque(false);
        actions.add(button("◐ テーマ", e -> toggleTheme()));
        actions.add(button("⚙ カスタマイズ", e -> openSettings()));
        actions.add(button("🛡 セキュリティ", e -> openSecurityReport()));
        actions.add(button("🔎 URLチェッカー", e -> openUrlChecker()));
        actions.add(button("💻 CodeBridge", e -> openCodeBridge()));
        actions.add(button("📝 掲示板", e -> openBoard()));
        actions.add(button("🎨 お絵かき", e -> openDrawing()));
        actions.add(button("🧬 文字化け", e -> openGarbler()));
        actions.add(button("🌙 おやすみ", e -> openSleepSettings()));
        actions.add(button("⚠ 開発者", e -> openDeveloper()));
        actions.add(button("＋ アプリ追加", e -> openAppManager()));
        actions.add(button("📰 ニュース", e -> openNews()));
        top.add(logo, BorderLayout.WEST); top.add(actions, BorderLayout.CENTER);
        root.add(top, BorderLayout.NORTH);

        JTabbedPane tabs = new JTabbedPane();
        tabs.setFont(tabs.getFont().deriveFont(Font.BOLD,13f));
        tabs.addTab("🏠 ホーム", buildHome());
        tabs.addTab("🗓 日常ツール", buildProductivity());
        tabs.addTab("🌤 天気・ネット", buildWeather());
        tabs.addTab("🧰 クリエイター", buildCreator());
        tabs.addTab("🔐 セキュリティ", buildSecurity());
        tabs.addTab("✦ Assistant+", buildAssistant());
        root.add(tabs, BorderLayout.CENTER);
        JPanel status = new JPanel(new BorderLayout()); status.setOpaque(false);
        systemLabel.setForeground(MUTED); systemLabel.setFont(systemLabel.getFont().deriveFont(11f));
        status.add(systemLabel, BorderLayout.WEST);
        JLabel footer = new JLabel("LOCAL-FIRST · Java " + Runtime.version().feature() + " · © 2026 NEXUS"); footer.setForeground(MUTED); footer.setFont(footer.getFont().deriveFont(10f));
        status.add(footer, BorderLayout.EAST); root.add(status, BorderLayout.SOUTH);
        setContentPane(root);
    }

    private JPanel buildHome() {
        JPanel page = page(); page.setLayout(new BorderLayout(10,10));
        JPanel hero = new glassPanel(); hero.setLayout(new BorderLayout(10,8));
        JPanel clockRow = new JPanel(new GridLayout(1,3,12,0)); clockRow.setOpaque(false);
        ClockFace face = new ClockFace(); face.setPreferredSize(new Dimension(120,120));
        JPanel digital = new JPanel(new GridLayout(2,1,0,0)); digital.setOpaque(false);
        clockLabel.setForeground(TEXT); clockLabel.setFont(clockLabel.getFont().deriveFont(Font.PLAIN,66f));
        dateLabel.setForeground(accent); dateLabel.setFont(dateLabel.getFont().deriveFont(Font.BOLD,14f));
        digital.add(clockLabel); digital.add(dateLabel);
        JLabel welcome = new JLabel("NEXUS SUPER 4.1",SwingConstants.CENTER); welcome.setForeground(accent); welcome.setFont(welcome.getFont().deriveFont(Font.BOLD,18f));
        clockRow.add(face); clockRow.add(digital); clockRow.add(welcome); hero.add(clockRow,BorderLayout.CENTER);
        JPanel search = new JPanel(new BorderLayout(6,0)); search.setOpaque(false);
        JTextField q = new JTextField(); q.setFont(q.getFont().deriveFont(17f)); q.setToolTipText("検索またはURLを入力");
        JComboBox<String> engine = new JComboBox<>(new String[]{"Google","Yahoo!","DuckDuckGo","Bing","Brave","Ecosia"});
        JButton searchBtn = button("検索 ↗", e -> searchWeb(q.getText(),String.valueOf(engine.getSelectedItem())));
        q.addActionListener(e -> searchWeb(q.getText(),String.valueOf(engine.getSelectedItem())));
        search.add(q,BorderLayout.CENTER); search.add(engine,BorderLayout.WEST); search.add(searchBtn,BorderLayout.EAST);
        hero.add(search,BorderLayout.SOUTH); page.add(hero,BorderLayout.NORTH);

        JPanel body = new JPanel(new BorderLayout(10,10)); body.setOpaque(false);
        JPanel categories = new JPanel(); categories.setOpaque(false); categories.setLayout(new BoxLayout(categories,BoxLayout.Y_AXIS));
        JTextField filter = new JTextField(); filter.setMaximumSize(new Dimension(Integer.MAX_VALUE,34)); filter.putClientProperty("JTextField.placeholderText","アプリ・サービスを検索");
        categories.add(filter); categories.add(Box.createVerticalStrut(8));
        Map<String,List<String[]>> groups = defaultApps();
        for (Map.Entry<String,List<String[]>> group : groups.entrySet()) {
            JPanel card = new glassPanel(); card.setLayout(new BorderLayout(5,5));
            JLabel label = new JLabel("▸ " + group.getKey()); label.setForeground(accent); label.setFont(label.getFont().deriveFont(Font.BOLD,14f)); card.add(label,BorderLayout.NORTH);
            JPanel links = new JPanel(new GridLayout(0,5,6,6)); links.setOpaque(false);
            for (String[] app : group.getValue()) {
                JButton b = button(app[0], e -> openSafeUrl(app[1])); b.setToolTipText(app[1]); b.setHorizontalAlignment(SwingConstants.CENTER);
                links.add(b);
            }
            card.add(links,BorderLayout.CENTER); card.setAlignmentX(Component.LEFT_ALIGNMENT); card.setMaximumSize(new Dimension(Integer.MAX_VALUE,160));
            categories.add(card); categories.add(Box.createVerticalStrut(7));
        }
        filter.getDocument().addDocumentListener(new DocumentListener(){public void insertUpdate(DocumentEvent e){applyFilter();}public void removeUpdate(DocumentEvent e){applyFilter();}public void changedUpdate(DocumentEvent e){applyFilter();}private void applyFilter(){String s=filter.getText().toLowerCase(Locale.ROOT);for(Component comp:categories.getComponents())if(comp instanceof JPanel p&&p.getComponentCount()>0&&p.getComponent(0) instanceof JLabel l){boolean match=s.isBlank()||l.getText().toLowerCase(Locale.ROOT).contains(s);if(p.getComponentCount()>1&&p.getComponent(1) instanceof JPanel grid){for(Component x:grid.getComponents()){if(x instanceof JButton btn){boolean m=s.isBlank()||btn.getText().toLowerCase(Locale.ROOT).contains(s)||btn.getToolTipText().toLowerCase(Locale.ROOT).contains(s);btn.setVisible(m);match|=m;}}}p.setVisible(match);}}});
        body.add(new JScrollPane(categories),BorderLayout.CENTER);
        JPanel side = new JPanel(); side.setOpaque(false); side.setLayout(new BoxLayout(side,BoxLayout.Y_AXIS));
        JPanel shortcuts = new glassPanel(); shortcuts.setLayout(new GridLayout(0,1,6,6));
        shortcuts.add(sectionTitle("クイック起動"));
        shortcuts.add(button("⌘ コマンドランチャー",e->openCommandPalette()));
        shortcuts.add(button("🌐 翻訳",e->openTranslation()));
        shortcuts.add(button("🧮 電卓",e->openCalculator()));
        shortcuts.add(button("📅 予定表",e->openProductivityTab("予定表")));
        shortcuts.add(button("✅ Todo",e->openProductivityTab("Todo")));
        shortcuts.add(button("🎮 ミニゲーム",e->openGames()));
        shortcuts.add(button("🔒 画面保護",e->activateScreenProtect()));
        JPanel sys = new glassPanel(); sys.setLayout(new BorderLayout(5,5)); sys.add(sectionTitle("システムモニター"),BorderLayout.NORTH);
        JTextArea sysText = new JTextArea(systemSummary()); sysText.setEditable(false); sysText.setOpaque(false); sysText.setForeground(TEXT); sysText.setLineWrap(true); sysText.setWrapStyleWord(true); sysText.setFont(sysText.getFont().deriveFont(11f));
        sys.add(sysText,BorderLayout.CENTER); sys.add(button("↻ 状態を更新",e->sysText.setText(systemSummary())),BorderLayout.SOUTH);
        side.add(shortcuts); side.add(Box.createVerticalStrut(8)); side.add(sys);
        body.add(side,BorderLayout.EAST); page.add(body,BorderLayout.CENTER);
        return page;
    }

    private JPanel buildProductivity() {
        JPanel page=page(); page.setLayout(new GridLayout(2,2,10,10));
        page.add(buildMemoPanel()); page.add(buildTodoPanel()); page.add(buildSchedulePanel()); page.add(buildTimeToolsPanel());
        return page;
    }

    private JPanel buildMemoPanel() {
        JPanel p=new glassPanel(); p.setLayout(new BorderLayout(6,6)); p.add(sectionTitle("📝 メモ"),BorderLayout.NORTH);
        JPanel split=new JPanel(new GridLayout(1,2,8,0)); split.setOpaque(false);
        memoList=new JList<>(memoModel); memoList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION); memoList.setVisibleRowCount(9);
        reloadMemos();
        memoList.addListSelectionListener(e->{if(!e.getValueIsAdjusting())loadSelectedMemo();});
        JPanel left=new JPanel(new BorderLayout(3,3));left.setOpaque(false);left.add(new JScrollPane(memoList),BorderLayout.CENTER);
        JButton newBtn=button("＋ 新規",e->{selectedMemoId="";memoList.clearSelection();memoTitle.setText("");memoEditor.setText("");});
        left.add(newBtn,BorderLayout.SOUTH);
        JPanel right=new JPanel(new BorderLayout(4,4));right.setOpaque(false);
        JPanel fields=new JPanel(new GridLayout(2,1,0,4));fields.setOpaque(false);memoTitle=new JTextField();memoTitle.setToolTipText("題名");memoEditor=new JTextArea(8,20);memoEditor.setLineWrap(true);memoEditor.setWrapStyleWord(true);
        fields.add(memoTitle);fields.add(new JScrollPane(memoEditor));right.add(fields,BorderLayout.CENTER);
        JPanel btns=new JPanel(new FlowLayout(FlowLayout.LEFT,4,0));btns.setOpaque(false);
        btns.add(button("💾 保存",e->saveMemo()));btns.add(button("📌 固定切替",e->toggleMemoPin()));btns.add(button("🗑 削除",e->deleteMemo()));right.add(btns,BorderLayout.SOUTH);
        split.add(left);split.add(right);p.add(split,BorderLayout.CENTER);return p;
    }

    private JPanel buildTodoPanel() {
        JPanel p=new glassPanel();p.setLayout(new BorderLayout(6,6));p.add(sectionTitle("✅ Todo"),BorderLayout.NORTH);
        JPanel top=new JPanel(new BorderLayout(5,0));top.setOpaque(false);JTextField date=new JTextField(todoDate,10);top.add(date,BorderLayout.WEST);
        todoInput=new JTextField();todoInput.setToolTipText("今日やることを追加");top.add(todoInput,BorderLayout.CENTER);
        top.add(button("＋",e->addTodo()),BorderLayout.EAST);
        date.addActionListener(e->{if(isDate(date.getText())){todoDate=date.getText();reloadTodos();}});
        todoList=new JList<>(todoModel);todoList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);todoList.setCellRenderer(new TodoRenderer());
        todoList.addMouseListener(new MouseAdapter(){public void mouseClicked(MouseEvent e){int i=todoList.locationToIndex(e.getPoint());if(i>=0&&e.getClickCount()==1)toggleTodo(i);}});
        JPanel south=new JPanel(new FlowLayout(FlowLayout.LEFT,4,0));south.setOpaque(false);south.add(button("📅 今日",e->{todoDate=LocalDate.now().toString();date.setText(todoDate);reloadTodos();}));south.add(button("完了分を削除",e->clearDoneTodos()));south.add(button("× 削除",e->deleteTodo()));
        p.add(top,BorderLayout.NORTH);p.add(new JScrollPane(todoList),BorderLayout.CENTER);p.add(south,BorderLayout.SOUTH);reloadTodos();return p;
    }

    private JPanel buildSchedulePanel() {
        JPanel p=new glassPanel();p.setLayout(new BorderLayout(6,6));p.add(sectionTitle("📅 予定表"),BorderLayout.NORTH);
        JPanel input=new JPanel(new GridLayout(3,1,4,4));input.setOpaque(false);eventDateTime=new JTextField(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));eventTitle=new JTextField();eventTitle.setToolTipText("予定");
        input.add(eventDateTime);input.add(eventTitle);input.add(button("＋ 予定を追加",e->addEvent()));
        eventList=new JList<>(eventModel);eventList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);reloadEvents();
        JPanel bottom=new JPanel(new FlowLayout(FlowLayout.LEFT,4,0));bottom.setOpaque(false);bottom.add(button("🗑 削除",e->deleteEvent()));bottom.add(button("📤 TXT保存",e->exportRows("NEXUS-予定.txt",readRows("events",3))));
        p.add(input,BorderLayout.NORTH);p.add(new JScrollPane(eventList),BorderLayout.CENTER);p.add(bottom,BorderLayout.SOUTH);return p;
    }

    private JPanel buildTimeToolsPanel() {
        JPanel p=new glassPanel();p.setLayout(new GridLayout(2,1,5,5));
        JPanel timer=new JPanel(new BorderLayout(4,4));timer.setOpaque(false);timer.add(sectionTitle("⏱ タイマー"),BorderLayout.NORTH);
        JPanel tmid=new JPanel(new FlowLayout(FlowLayout.CENTER,6,4));tmid.setOpaque(false);JSpinner minutes=new JSpinner(new SpinnerNumberModel(5,1,999,1));timerLabel.setForeground(accent);timerLabel.setFont(timerLabel.getFont().deriveFont(Font.BOLD,35f));tmid.add(new JLabel("分"));tmid.add(minutes);tmid.add(timerLabel);timer.add(tmid,BorderLayout.CENTER);
        JPanel tb=new JPanel(new FlowLayout(FlowLayout.CENTER,5,0));tb.setOpaque(false);tb.add(button("▶ 開始 / 一時停止",e->{if(countRunning)pauseCountdown();else startCountdown((Integer)minutes.getValue());}));tb.add(button("↺ リセット",e->resetCountdown()));timer.add(tb,BorderLayout.SOUTH);
        JPanel sw=new JPanel(new BorderLayout(4,4));sw.setOpaque(false);sw.add(sectionTitle("⏲ ストップウォッチ"),BorderLayout.NORTH);stopwatchLabel.setForeground(accent);stopwatchLabel.setFont(stopwatchLabel.getFont().deriveFont(Font.BOLD,32f));sw.add(stopwatchLabel,BorderLayout.CENTER);
        JPanel sb=new JPanel(new FlowLayout(FlowLayout.CENTER,5,0));sb.setOpaque(false);sb.add(button("▶ / Ⅱ",e->toggleStopwatch()));sb.add(button("🏁 ラップ",e->recordLap()));sb.add(button("↺",e->resetStopwatch()));sw.add(sb,BorderLayout.SOUTH);
        p.add(timer);p.add(sw);return p;
    }

    private JPanel buildWeather() {
        JPanel p=page();p.setLayout(new BorderLayout(10,10));
        JPanel head=new glassPanel();head.setLayout(new BorderLayout(8,6));head.add(sectionTitle("🌤 日本の都道府県別 天気"),BorderLayout.NORTH);
        JPanel controls=new JPanel(new FlowLayout(FlowLayout.LEFT,6,0));controls.setOpaque(false);prefectureBox=new JComboBox<>(PREFECTURES);prefectureBox.setSelectedItem(get("weather.prefecture","東京都"));
        JButton refresh=button("🔄 更新",e->loadWeather(true));JButton hourly=button("☔ 24時間予報",e->loadWeather(true));autoWeatherBox=new JCheckBox("起動時の自動取得を許可",autoWeather);styleCheck(autoWeatherBox);autoWeatherBox.addActionListener(e->{autoWeather=autoWeatherBox.isSelected();putBool("setting.autoWeather",autoWeather);});
        controls.add(prefectureBox);controls.add(refresh);controls.add(hourly);controls.add(autoWeatherBox);head.add(controls,BorderLayout.CENTER);p.add(head,BorderLayout.NORTH);
        JPanel content=new JPanel(new GridLayout(1,2,10,0));content.setOpaque(false);
        JPanel summary=new glassPanel();summary.setLayout(new BorderLayout(8,8));weatherLabel.setForeground(accent);weatherLabel.setFont(weatherLabel.getFont().deriveFont(Font.BOLD,20f));summary.add(weatherLabel,BorderLayout.NORTH);
        weatherDetails=new JTextArea("プライバシー保護のため、天気情報は手動更新が初期設定です。\n都道府県を選んで「更新」を押してください。\nデータ提供：Open-Meteo");weatherDetails.setEditable(false);weatherDetails.setLineWrap(true);weatherDetails.setWrapStyleWord(true);weatherDetails.setOpaque(false);weatherDetails.setForeground(TEXT);summary.add(new JScrollPane(weatherDetails),BorderLayout.CENTER);
        JPanel info=new glassPanel();info.setLayout(new BorderLayout(5,5));info.add(sectionTitle("ネットワーク・情報"),BorderLayout.NORTH);
        JTextArea tips=new JTextArea("天気はOpen-Meteo APIから取得します。\n自動取得は初期状態でオフです。\n通信匿名モードが有効な場合、外部通信はブロックされます。\n\nネットワーク速度測定は約5MBのデータを取得します。通信量にご注意ください。");tips.setEditable(false);tips.setOpaque(false);tips.setForeground(MUTED);tips.setLineWrap(true);tips.setWrapStyleWord(true);info.add(tips,BorderLayout.CENTER);
        info.add(button("⚡ 速度を実測（約5MB）",e->runSpeedTest()),BorderLayout.SOUTH);
        content.add(summary);content.add(info);p.add(content,BorderLayout.CENTER);
        if(autoWeather) SwingUtilities.invokeLater(()->loadWeather(false));
        return p;
    }

    private JPanel buildCreator() {
        JPanel p=page();p.setLayout(new GridLayout(2,2,10,10));
        JPanel bridge=new glassPanel();bridge.setLayout(new BorderLayout(6,6));bridge.add(sectionTitle("💻 CodeBridge"),BorderLayout.NORTH);
        JTextArea desc=new JTextArea("複数言語の基本構文変換と、プログラム作成ワークスペースを利用できます。\n変換結果は必ず実行前に確認してください。");desc.setEditable(false);desc.setOpaque(false);desc.setForeground(MUTED);desc.setLineWrap(true);desc.setWrapStyleWord(true);bridge.add(desc,BorderLayout.CENTER);bridge.add(button("🚀 CodeBridgeを開く",e->openCodeBridge()),BorderLayout.SOUTH);
        JPanel music=new glassPanel();music.setLayout(new BorderLayout(6,6));music.add(sectionTitle("🎧 ミュージックプレーヤー"),BorderLayout.NORTH);
        JLabel fileLabel=new JLabel("ファイル未選択",SwingConstants.CENTER);fileLabel.setForeground(MUTED);music.add(fileLabel,BorderLayout.CENTER);
        JPanel mb=new JPanel(new FlowLayout(FlowLayout.CENTER,5,0));mb.setOpaque(false);mb.add(button("📂 WAVを選ぶ",e->{chooseAudio(fileLabel);}));mb.add(button("▶ / Ⅱ",e->toggleAudio()));mb.add(button("■ 停止",e->stopAudio()));music.add(mb,BorderLayout.SOUTH);
        JPanel draw=new glassPanel();draw.setLayout(new BorderLayout(6,6));draw.add(sectionTitle("🎨 お絵かきスタジオ"),BorderLayout.NORTH);draw.add(new JLabel("ペン・蛍光・消しゴム・図形・文字。PNG保存対応。",SwingConstants.CENTER),BorderLayout.CENTER);draw.add(button("スタジオを開く",e->openDrawing()),BorderLayout.SOUTH);
        JPanel garble=new glassPanel();garble.setLayout(new BorderLayout(6,6));garble.add(sectionTitle("🧬 文字化けラボ"),BorderLayout.NORTH);garble.add(new JLabel("文章を文字化け風・記号ノイズへ変換（ローカル処理）",SwingConstants.CENTER),BorderLayout.CENTER);garble.add(button("ラボを開く",e->openGarbler()),BorderLayout.SOUTH);
        p.add(bridge);p.add(music);p.add(draw);p.add(garble);return p;
    }

    private JPanel buildSecurity() {
        JPanel p=page();p.setLayout(new GridLayout(2,2,10,10));
        JPanel report=new glassPanel();report.setLayout(new BorderLayout(6,6));report.add(sectionTitle("🛡 セキュリティ・プライバシーレポート"),BorderLayout.NORTH);
        JTextArea r=new JTextArea("ローカル環境の設定と保存データを簡易点検します。\nこの診断はウイルススキャンや侵入検知ではありません。");r.setOpaque(false);r.setForeground(MUTED);r.setEditable(false);report.add(r,BorderLayout.CENTER);report.add(button("診断を実行",e->r.setText(securityReport())),BorderLayout.SOUTH);
        JPanel url=new glassPanel();url.setLayout(new BorderLayout(6,6));url.add(sectionTitle("🔎 URLチェッカー"),BorderLayout.NORTH);url.add(new JLabel("URLの形式、IP表記、短縮URL、疑わしい文字列をローカル分析。",SwingConstants.CENTER),BorderLayout.CENTER);url.add(button("URLを検査",e->openUrlChecker()),BorderLayout.SOUTH);
        JPanel privacy=new glassPanel();privacy.setLayout(new BoxLayout(privacy,BoxLayout.Y_AXIS));privacy.add(sectionTitle("🕵 プライバシー設定"));
        autoWeatherBox=new JCheckBox("天気の自動外部通信を許可",autoWeather);styleCheck(autoWeatherBox);autoWeatherBox.addActionListener(e->{autoWeather=autoWeatherBox.isSelected();putBool("setting.autoWeather",autoWeather);});
        anonymousBox=new JCheckBox("通信匿名モード（外部通信をブロック）",anonymousMode);styleCheck(anonymousBox);anonymousBox.addActionListener(e->{anonymousMode=anonymousBox.isSelected();putBool("setting.anonymous",anonymousMode);});
        privacyBlurBox=new JCheckBox("フォーカスを失った時にタイトルを保護表示",privacyBlur);styleCheck(privacyBlurBox);privacyBlurBox.addActionListener(e->{privacyBlur=privacyBlurBox.isSelected();putBool("setting.privacyBlur",privacyBlur);});
        screenProtectBox=new JCheckBox("画面保護モードを有効化",screenProtect);styleCheck(screenProtectBox);screenProtectBox.addActionListener(e->{screenProtect=screenProtectBox.isSelected();putBool("setting.screenProtect",screenProtect);});
        privacy.add(autoWeatherBox);privacy.add(anonymousBox);privacy.add(privacyBlurBox);privacy.add(screenProtectBox);privacy.add(button("🔒 画面を今すぐ保護",e->activateScreenProtect()));privacy.add(button("🗑 NEXUS保存データを消去",e->clearOwnedData()));
        JPanel backup=new glassPanel();backup.setLayout(new BorderLayout(6,6));backup.add(sectionTitle("💾 バックアップ"),BorderLayout.NORTH);backup.add(new JLabel("設定・メモ・Todo・予定・掲示板などを一括保存。AES-GCM暗号化対応。",SwingConstants.CENTER),BorderLayout.CENTER);JPanel bb=new JPanel(new FlowLayout(FlowLayout.CENTER,5,0));bb.setOpaque(false);bb.add(button("⬇ エクスポート",e->exportBackup()));bb.add(button("⬆ インポート",e->importBackup()));backup.add(bb,BorderLayout.SOUTH);
        p.add(report);p.add(url);p.add(privacy);p.add(backup);return p;
    }

    private JPanel buildAssistant() {
        JPanel p=page();p.setLayout(new BorderLayout(8,8));JPanel chat=new glassPanel();chat.setLayout(new BorderLayout(7,7));chat.add(sectionTitle("✦ NEXUS Assistant+"),BorderLayout.NORTH);
        assistantReply=new JLabel("こんにちは！メモ・Todo・予定・計算などのローカル操作を手伝います。",SwingConstants.LEFT);assistantReply.setForeground(TEXT);assistantReply.setBorder(new EmptyBorder(10,10,10,10));
        JTextArea conversation=new JTextArea();conversation.setEditable(false);conversation.setLineWrap(true);conversation.setWrapStyleWord(true);conversation.setBackground(new Color(4,12,28));conversation.setForeground(TEXT);conversation.setText("NEXUS Assistant+\nローカルコマンド例：\n・メモ: アイデアを書く\n・Todo: 英単語を復習\n・予定 2026-11-05 14:00 歯医者\n・計算: (12+8)*3\n・翻訳: Hello!\n\n幅広い質問や最新情報は、外部AIまたはWeb検索へ手動で引き継げます。入力内容は自動送信されません。\n");
        JScrollPane sc=new JScrollPane(conversation);JPanel form=new JPanel(new BorderLayout(5,0));form.setOpaque(false);assistantInput=new JTextField();assistantInput.addActionListener(e->handleAssistant(conversation));form.add(assistantInput,BorderLayout.CENTER);form.add(button("実行 ↗",e->handleAssistant(conversation)),BorderLayout.EAST);
        JPanel quick=new JPanel(new FlowLayout(FlowLayout.LEFT,5,0));quick.setOpaque(false);for(String s:new String[]{"天気","予定","Todo","メモを作成","翻訳","文字化け"})quick.add(button(s,e->{assistantInput.setText(s);handleAssistant(conversation);}));
        JPanel south=new JPanel(new BorderLayout(4,4));south.setOpaque(false);south.add(form,BorderLayout.NORTH);south.add(quick,BorderLayout.SOUTH);
        chat.add(sc,BorderLayout.CENTER);chat.add(south,BorderLayout.SOUTH);p.add(chat,BorderLayout.CENTER);
        JPanel ai=new JPanel(new FlowLayout(FlowLayout.CENTER,7,4));ai.setOpaque(false);ai.add(button("🤖 ChatGPTを開く",e->openSafeUrl("https://chatgpt.com/")));ai.add(button("✨ Geminiを開く",e->openSafeUrl("https://gemini.google.com/")));ai.add(button("🔎 Web検索",e->searchWeb(assistantInput.getText(),"Google")));p.add(ai,BorderLayout.SOUTH);return p;
    }

    private JPanel page(){JPanel p=new NebulaPanel();p.setBorder(new EmptyBorder(8,8,8,8));return p;}
    private class glassPanel extends JPanel { glassPanel(){setOpaque(true);setBackground(PANEL);setBorder(new CompoundBorder(new LineBorder(new Color(accent.getRed(),accent.getGreen(),accent.getBlue(),110),1,true),new EmptyBorder(10,10,10,10)));} }
    private JLabel sectionTitle(String s){JLabel l=new JLabel(s);l.setForeground(accent);l.setFont(l.getFont().deriveFont(Font.BOLD,14f));return l;}
    private JButton button(String s,ActionListener a){JButton b=new JButton(s);b.setFocusPainted(false);b.setForeground(TEXT);b.setBackground(PANEL2);b.setBorder(new CompoundBorder(new LineBorder(new Color(accent.getRed(),accent.getGreen(),accent.getBlue(),130),1,true),new EmptyBorder(6,10,6,10)));b.addActionListener(a);b.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));return b;}
    private void styleCheck(JCheckBox c){c.setOpaque(false);c.setForeground(TEXT);c.setFocusPainted(false);}

    private void startClocks(){clockTimer=new javax.swing.Timer(250,e->{LocalDateTime now=LocalDateTime.now();clockLabel.setText(now.format(DateTimeFormatter.ofPattern("HH:mm:ss")));dateLabel.setText(now.format(DateTimeFormatter.ofPattern("yyyy年M月d日（E）",Locale.JAPANESE)));systemLabel.setText("LOCAL-FIRST · " + now.format(DateTimeFormatter.ofPattern("HH:mm:ss")) + " · 保存先 " + DATA_DIR);});clockTimer.start();}
    private void toggleTheme(){getContentPane().setBackground(getContentPane().getBackground().equals(Color.WHITE)?BG:new Color(19,27,48));repaint();JOptionPane.showMessageDialog(this,"NEXUSの配色テーマを切り替えました。","テーマ",JOptionPane.INFORMATION_MESSAGE);}
    private void openSafeUrl(String raw){if(anonymousMode){JOptionPane.showMessageDialog(this,"通信匿名モードが有効なため、外部サイトを開けません。","通信ブロック",JOptionPane.WARNING_MESSAGE);return;}try{String s=raw.trim();if(s.isEmpty())return;URI u=new URI(s.contains(":")?s:"https://"+s);String scheme=u.getScheme();if("http".equalsIgnoreCase(scheme))u=new URI("https",u.getUserInfo(),u.getHost(),u.getPort(),u.getPath(),u.getQuery(),u.getFragment());if(!"https".equalsIgnoreCase(u.getScheme())||u.getHost()==null||u.getUserInfo()!=null)throw new Exception("HTTPS URLを入力してください（認証情報付きURLは不可）。");Desktop.getDesktop().browse(u);}catch(Exception ex){JOptionPane.showMessageDialog(this,"URLを開けません: "+ex.getMessage(),"URLエラー",JOptionPane.ERROR_MESSAGE);}}
    private void searchWeb(String query,String engine){String q=query==null?"":query.trim();if(q.isEmpty())return;String base=switch(engine){case "Yahoo!"->"https://search.yahoo.co.jp/search?p=";case "DuckDuckGo"->"https://duckduckgo.com/?q=";case "Bing"->"https://www.bing.com/search?q=";case "Brave"->"https://search.brave.com/search?q=";case "Ecosia"->"https://www.ecosia.org/search?q=";default->"https://www.google.com/search?q=";};openSafeUrl(base+URLEncoder.encode(q,StandardCharsets.UTF_8));}

    private Map<String,List<String[]>> defaultApps(){Map<String,List<String[]>> m=new LinkedHashMap<>();
        addGroup(m,"Google","Gmail|https://mail.google.com","ドキュメント|https://docs.google.com/document","スライド|https://docs.google.com/presentation","スプレッドシート|https://docs.google.com/spreadsheets","ドライブ|https://drive.google.com","Colab|https://colab.research.google.com","カレンダー|https://calendar.google.com","マップ|https://maps.google.com","フォト|https://photos.google.com","Meet|https://meet.google.com","フォーム|https://docs.google.com/forms","Keep|https://keep.google.com","翻訳|https://translate.google.com","Sites|https://sites.google.com","Gemini|https://gemini.google.com","Classroom|https://classroom.google.com");
        addGroup(m,"Microsoft","Word|https://www.office.com/launch/word","Excel|https://www.office.com/launch/excel","PowerPoint|https://www.office.com/launch/powerpoint","Teams|https://teams.microsoft.com","Outlook|https://outlook.live.com","OneNote|https://www.onenote.com","Copilot|https://copilot.microsoft.com","OneDrive|https://onedrive.live.com","Microsoft 365|https://www.microsoft365.com","To Do|https://to-do.office.com","Forms|https://forms.office.com");
        addGroup(m,"AI","ChatGPT|https://chatgpt.com","Claude|https://claude.ai","Perplexity|https://www.perplexity.ai","Gemini|https://gemini.google.com","Copilot|https://copilot.microsoft.com","Grok|https://grok.com","Suno|https://suno.com","Sora|https://sora.com","Runway|https://runwayml.com","Cursor|https://cursor.com","Midjourney|https://www.midjourney.com");
        addGroup(m,"SNS・動画","X|https://x.com","NOTE|https://note.com","TikTok|https://www.tiktok.com","YouTube|https://www.youtube.com","Netflix|https://www.netflix.com","Twitch|https://www.twitch.tv","Reddit|https://www.reddit.com","Facebook|https://www.facebook.com","Instagram|https://www.instagram.com","Threads|https://www.threads.net","LINE|https://line.me","Discord|https://discord.com","Spotify|https://open.spotify.com");
        addGroup(m,"クラウド・開発","Dropbox|https://www.dropbox.com","Google Drive|https://drive.google.com","iCloud|https://www.icloud.com","Box|https://www.box.com","GitHub|https://github.com","Unity|https://unity.com","Steam|https://store.steampowered.com","Vercel|https://vercel.com","Scratch|https://scratch.mit.edu","TurboWarp|https://turbowarp.org");
        addGroup(m,"ネット・学習","Amazon|https://www.amazon.co.jp","楽天市場|https://www.rakuten.co.jp","Yahoo! JAPAN|https://www.yahoo.co.jp","メルカリ|https://jp.mercari.com","Wikipedia|https://ja.wikipedia.org","NHK|https://www3.nhk.or.jp","Zoom|https://zoom.us","Slack|https://slack.com","Notion|https://www.notion.so","Canva|https://www.canva.com","Figma|https://www.figma.com","Qiita|https://qiita.com","Zenn|https://zenn.dev","GeoGebra|https://www.geogebra.org","Desmos|https://www.desmos.com");
        List<String[]> custom=readRows("customApps",2); if(!custom.isEmpty()) m.put("ユーザー追加",custom);
        return m;
    }
    private void addGroup(Map<String,List<String[]>> m,String group,String... entries){List<String[]> list=new ArrayList<>();for(String e:entries){int i=e.indexOf('|');list.add(new String[]{e.substring(0,i),e.substring(i+1)});}m.put(group,list);}

    private void openAppManager(){
        JDialog d=new JDialog(this,"NEXUS アプリ追加・管理",true);d.setSize(620,460);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(7,7));
        DefaultListModel<String> model=new DefaultListModel<>();JList<String> list=new JList<>(model);List<String[]> rows=readRows("customApps",2);
        Runnable reload=()->{model.clear();for(String[]r:rows)model.addElement(r[0]+"  —  "+r[1]);};reload.run();
        JPanel fields=new JPanel(new GridLayout(2,2,5,5));JTextField name=new JTextField(),url=new JTextField();fields.add(new JLabel("アプリ名"));fields.add(name);fields.add(new JLabel("URL（HTTPS）"));fields.add(url);
        JPanel controls=new JPanel();controls.add(button("＋ 追加",e->{String n=name.getText().trim(),u=url.getText().trim();if(n.isEmpty()||u.isEmpty()){showInfo("アプリ名とURLを入力してください。");return;}try{URI v=new URI(u.matches("^[a-zA-Z][a-zA-Z0-9+.-]*://.*")?u:"https://"+u);if(!"https".equalsIgnoreCase(v.getScheme())||v.getHost()==null||v.getUserInfo()!=null)throw new Exception("HTTPS URLを入力してください。");if(rows.size()>=120)throw new Exception("登録できるアプリは120件までです。");rows.add(new String[]{n.substring(0,Math.min(100,n.length())),v.toString()});writeRows("customApps",rows);reload.run();name.setText("");url.setText("");}catch(Exception ex){showInfo("URLを登録できません: "+ex.getMessage());}}));
        controls.add(button("選択項目を削除",e->{int i=list.getSelectedIndex();if(i>=0){rows.remove(i);writeRows("customApps",rows);reload.run();}}));controls.add(button("この一覧を開く",e->{int i=list.getSelectedIndex();if(i>=0)openSafeUrl(rows.get(i)[1]);}));
        JPanel north=new JPanel(new BorderLayout(5,5));north.add(fields,BorderLayout.CENTER);north.add(controls,BorderLayout.SOUTH);d.add(north,BorderLayout.NORTH);d.add(new JScrollPane(list),BorderLayout.CENTER);d.add(button("閉じる",e->d.dispose()),BorderLayout.SOUTH);d.setVisible(true);
    }

    private String systemSummary(){Runtime r=Runtime.getRuntime();return "OS: "+System.getProperty("os.name")+"\nJava: "+Runtime.version()+"\nCPU processors: "+r.availableProcessors()+"\nMemory used: "+((r.totalMemory()-r.freeMemory())/1024/1024)+" MiB\nMemory max: "+(r.maxMemory()/1024/1024)+" MiB\nLocal data: "+DATA_FILE+"\nAutomatic weather: "+(autoWeather?"ON":"OFF")+"\nAnonymous mode: "+(anonymousMode?"ON":"OFF");}

    // Productivity: Memo, Todo, schedule
    private void reloadMemos(){if(memoModel==null)return;memoModel.clear();memoIds.clear();List<String[]> rows=readRows("memos",5);rows.sort((a,b)->Boolean.compare(Boolean.parseBoolean(b[3]),Boolean.parseBoolean(a[3])));int i=0;for(String[] r:rows){memoModel.addElement((Boolean.parseBoolean(r[3])?"📌 ":"📝 ")+r[1]);memoIds.put(i++,r[0]);}}
    private void loadSelectedMemo(){int i=memoList.getSelectedIndex();if(i<0)return;String id=memoIds.get(i);for(String[]r:readRows("memos",5))if(r[0].equals(id)){selectedMemoId=id;memoTitle.setText(r[1]);memoEditor.setText(r[2]);break;}}
    private void saveMemo(){String title=memoTitle.getText().trim(),body=memoEditor.getText();if(title.isEmpty()){showInfo("題名を入力してください。");return;}List<String[]> rows=readRows("memos",5);String id=selectedMemoId.isEmpty()?UUID.randomUUID().toString():selectedMemoId;boolean found=false;for(String[]r:rows)if(r[0].equals(id)){r[1]=title;r[2]=body;r[4]=Instant.now().toString();found=true;}if(!found)rows.add(new String[]{id,title,body,"false",Instant.now().toString()});writeRows("memos",rows);selectedMemoId=id;reloadMemos();showInfo("メモを保存しました。");}
    private void toggleMemoPin(){if(selectedMemoId.isEmpty())return;List<String[]> rows=readRows("memos",5);for(String[]r:rows)if(r[0].equals(selectedMemoId))r[3]=Boolean.toString(!Boolean.parseBoolean(r[3]));writeRows("memos",rows);reloadMemos();}
    private void deleteMemo(){if(selectedMemoId.isEmpty())return;if(JOptionPane.showConfirmDialog(this,"選択中のメモを削除しますか？","確認",JOptionPane.YES_NO_OPTION)!=JOptionPane.YES_OPTION)return;List<String[]> rows=readRows("memos",5);rows.removeIf(r->r[0].equals(selectedMemoId));writeRows("memos",rows);selectedMemoId="";memoTitle.setText("");memoEditor.setText("");reloadMemos();}
    private void addTodo(){String text=todoInput.getText().trim();if(text.isEmpty())return;List<String[]> rows=readRows("todo."+todoDate,3);if(rows.size()>=200){showInfo("1日あたりのTodoは最大200件です。");return;}rows.add(new String[]{UUID.randomUUID().toString(),text,"false"});writeRows("todo."+todoDate,rows);todoInput.setText("");reloadTodos();}
    private void reloadTodos(){if(todoModel==null)return;todoModel.clear();todoIds.clear();List<String[]> rows=readRows("todo."+todoDate,3);int i=0;for(String[]r:rows){todoModel.addElement((Boolean.parseBoolean(r[2])?"☑ ":"□ ")+r[1]);todoIds.put(i++,r[0]);}}
    private void toggleTodo(int index){String id=todoIds.get(index);List<String[]> rows=readRows("todo."+todoDate,3);for(String[]r:rows)if(r[0].equals(id))r[2]=Boolean.toString(!Boolean.parseBoolean(r[2]));writeRows("todo."+todoDate,rows);reloadTodos();}
    private void deleteTodo(){int i=todoList.getSelectedIndex();if(i<0)return;String id=todoIds.get(i);List<String[]>rows=readRows("todo."+todoDate,3);rows.removeIf(r->r[0].equals(id));writeRows("todo."+todoDate,rows);reloadTodos();}
    private void clearDoneTodos(){List<String[]>rows=readRows("todo."+todoDate,3);rows.removeIf(r->Boolean.parseBoolean(r[2]));writeRows("todo."+todoDate,rows);reloadTodos();}
    private void reloadEvents(){if(eventModel==null)return;eventModel.clear();eventIds.clear();List<String[]>rows=readRows("events",3);rows.sort(Comparator.comparing(a->a[1]));int i=0;for(String[]r:rows){eventModel.addElement(r[1]+"  —  "+r[2]);eventIds.put(i++,r[0]);}}
    private void addEvent(){String dt=eventDateTime.getText().trim(),title=eventTitle.getText().trim();if(title.isEmpty()){showInfo("予定名を入力してください。");return;}try{LocalDateTime.parse(dt,DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));}catch(Exception ex){showInfo("日時は yyyy-MM-dd HH:mm 形式で入力してください。");return;}List<String[]>rows=readRows("events",3);rows.add(new String[]{UUID.randomUUID().toString(),dt,title});writeRows("events",rows);eventTitle.setText("");reloadEvents();}
    private void deleteEvent(){int i=eventList.getSelectedIndex();if(i<0)return;String id=eventIds.get(i);List<String[]>rows=readRows("events",3);rows.removeIf(r->r[0].equals(id));writeRows("events",rows);reloadEvents();}
    private boolean isDate(String x){try{LocalDate.parse(x);return true;}catch(Exception e){return false;}}
    private void exportRows(String filename,List<String[]>rows){StringBuilder b=new StringBuilder("NEXUS SUPER 4.1\n");for(String[]r:rows)b.append(String.join("\t",r)).append('\n');saveTextFile(filename,b.toString());}

    // Timer and stopwatch
    private void startCountdown(int minutes){if(minutes<1)return;countEndsAt=System.currentTimeMillis()+minutes*60_000L;countRunning=true;if(countTimer!=null)countTimer.stop();countTimer=new javax.swing.Timer(200,e->{long left=countEndsAt-System.currentTimeMillis();if(left<=0){countRunning=false;countTimer.stop();timerLabel.setText("00:00");Toolkit.getDefaultToolkit().beep();JOptionPane.showMessageDialog(this,"タイマーが終了しました。","NEXUS Timer",JOptionPane.INFORMATION_MESSAGE);}else timerLabel.setText(String.format("%02d:%02d",left/60000,(left/1000)%60));});countTimer.start();}
    private void pauseCountdown(){countRunning=false;if(countTimer!=null)countTimer.stop();}
    private void resetCountdown(){pauseCountdown();timerLabel.setText("05:00");}
    private void toggleStopwatch(){if(stopwatchRunning){stopwatchElapsed+=System.currentTimeMillis()-stopwatchStartedAt;stopwatchRunning=false;if(stopwatchTimer!=null)stopwatchTimer.stop();}else{stopwatchStartedAt=System.currentTimeMillis();stopwatchRunning=true;stopwatchTimer=new javax.swing.Timer(30,e->{long ms=stopwatchElapsed+(System.currentTimeMillis()-stopwatchStartedAt);stopwatchLabel.setText(String.format("%02d:%02d.%02d",ms/60000,(ms/1000)%60,(ms/10)%100));});stopwatchTimer.start();}}
    private void recordLap(){if(!stopwatchRunning&&stopwatchElapsed==0)return;String lap=stopwatchLabel.getText();JOptionPane.showMessageDialog(this,"ラップタイム: "+lap,"ストップウォッチ",JOptionPane.INFORMATION_MESSAGE);}
    private void resetStopwatch(){if(stopwatchTimer!=null)stopwatchTimer.stop();stopwatchRunning=false;stopwatchElapsed=0;stopwatchLabel.setText("00:00.00");}

    // Weather and speed test
    private void loadWeather(boolean manual){if(anonymousMode){weatherLabel.setText("通信匿名モード：外部通信を停止中");return;}if(!manual&&!autoWeather)return;String pref=String.valueOf(prefectureBox==null?get("weather.prefecture","東京都"):prefectureBox.getSelectedItem());int idx=Arrays.asList(PREFECTURES).indexOf(pref);if(idx<0)idx=12;final int ix=idx;put("weather.prefecture",pref);weatherLabel.setText(pref+" の天気を取得中…");
        workers.submit(()->{try{double lat=PREF_COORDS[ix][0],lon=PREF_COORDS[ix][1];String url="https://api.open-meteo.com/v1/forecast?latitude="+lat+"&longitude="+lon+"&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&hourly=precipitation_probability,precipitation&forecast_days=1&timezone=Asia%2FTokyo";HttpRequest req=HttpRequest.newBuilder(URI.create(url)).timeout(java.time.Duration.ofSeconds(12)).header("User-Agent","NEXUS-SUPER/4.1").GET().build();HttpResponse<String> res=HttpClient.newHttpClient().send(req,HttpResponse.BodyHandlers.ofString());if(res.statusCode()!=200)throw new IOException("HTTP "+res.statusCode());String json=res.body();String current=between(json,"\"current\"", "\"hourly\"");double temp=num(current,"temperature_2m",Double.NaN),feel=num(current,"apparent_temperature",Double.NaN),wind=num(current,"wind_speed_10m",Double.NaN),rain=num(current,"precipitation",Double.NaN),hum=num(current,"relative_humidity_2m",Double.NaN);int code=(int)num(current,"weather_code",-1);String time=str(current,"time");String hourly=between(json,"\"hourly\"", "\"hourly_units\"");String[] times=array(hourly,"time"),pr=array(hourly,"precipitation_probability"),mm=array(hourly,"precipitation");StringBuilder lines=new StringBuilder();lines.append("取得時刻: ").append(time).append("\n現在気温: ").append(fmt(temp)).append("℃\n体感温度: ").append(fmt(feel)).append("℃\n湿度: ").append(fmt(hum)).append("%\n風速: ").append(fmt(wind)).append(" km/h\n降水量: ").append(fmt(rain)).append(" mm\n天気コード: ").append(code).append(" (Open-Meteo)\n\n今後24時間の降水量・降水確率\n");for(int i=0;i<Math.min(24,Math.min(times.length,Math.min(pr.length,mm.length)));i++)lines.append(times[i].replaceAll("^.*T","" )).append("  ").append(mm[i]).append(" mm / ").append(pr[i]).append("%\n");final String out=lines.toString(),headline=pref+"  "+weatherWord(code)+"  "+fmt(temp)+"℃";SwingUtilities.invokeLater(()->{weatherLabel.setText(headline);weatherDetails.setText(out);weatherDetails.setCaretPosition(0);lastWeatherFetch=System.currentTimeMillis();});}catch(Exception ex){SwingUtilities.invokeLater(()->{weatherLabel.setText("天気を取得できませんでした");weatherDetails.setText("取得エラー: "+ex.getMessage()+"\nネットワーク接続と通信設定を確認してください。");});}});
    }
    private static String between(String s,String a,String b){int i=s.indexOf(a),j=s.indexOf(b,Math.max(0,i));return i<0?"":s.substring(i,j<0?s.length():j);}
    private static double num(String s,String key,double fallback){Matcher m=Pattern.compile("\\\""+Pattern.quote(key)+"\\\"\\s*:\\s*(-?[0-9]+(?:\\.[0-9]+)?)").matcher(s);return m.find()?Double.parseDouble(m.group(1)):fallback;}
    private static String str(String s,String key){Matcher m=Pattern.compile("\\\""+Pattern.quote(key)+"\\\"\\s*:\\s*\\\"([^\\\"]*)\\\"").matcher(s);return m.find()?m.group(1):"—";}
    private static String[] array(String s,String key){Matcher m=Pattern.compile("\\\""+Pattern.quote(key)+"\\\"\\s*:\\s*\\[([^\\]]*)\\]").matcher(s);if(!m.find())return new String[0];return Arrays.stream(m.group(1).split(",")).map(x->x.replaceAll("[\\\" ]","" )).toArray(String[]::new);}
    private static String fmt(double n){return Double.isFinite(n)?String.format(Locale.JAPAN,"%.1f",n):"—";}
    private static String weatherWord(int c){if(c==0)return "快晴";if(c<=3&&c>=1)return "晴れ・曇り";if(c>=45&&c<=48)return "霧";if(c>=51&&c<=67)return "雨";if(c>=71&&c<=77)return "雪";if(c>=80&&c<=82)return "にわか雨";if(c>=95)return "雷雨";return "天気情報";}
    private void runSpeedTest(){if(anonymousMode){showInfo("通信匿名モードが有効です。");return;}JDialog d=busyDialog("ネットワーク速度を測定中…", "Cloudflareから約5MBを取得します。");workers.submit(()->{long st=System.nanoTime();try{HttpRequest req=HttpRequest.newBuilder(URI.create("https://speed.cloudflare.com/__down?bytes=5000000")).timeout(java.time.Duration.ofSeconds(25)).GET().build();HttpResponse<byte[]>res=HttpClient.newHttpClient().send(req,HttpResponse.BodyHandlers.ofByteArray());double sec=(System.nanoTime()-st)/1e9,mbps=(res.body().length*8/1_000_000.0)/sec;SwingUtilities.invokeLater(()->{d.dispose();JOptionPane.showMessageDialog(this,String.format(Locale.JAPAN,"受信量: %.2f MB\n所要時間: %.2f 秒\n推定ダウンロード速度: %.2f Mbps",res.body().length/1e6,sec,mbps),"測定結果",JOptionPane.INFORMATION_MESSAGE);});}catch(Exception ex){SwingUtilities.invokeLater(()->{d.dispose();showError("速度測定に失敗しました",ex);});}});d.setVisible(true);}

    // Translator and calculator
    private void openTranslation(){JDialog d=new JDialog(this,"NEXUS 翻訳",true);d.setSize(820,600);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(8,8));JComboBox<String> from=new JComboBox<>(new String[]{"日本語","英語","中国語","韓国語","フランス語","ドイツ語","スペイン語"}),to=new JComboBox<>(new String[]{"英語","日本語","中国語","韓国語","フランス語","ドイツ語","スペイン語"});JTextArea in=new JTextArea(),out=new JTextArea();in.setLineWrap(true);out.setLineWrap(true);out.setEditable(false);JPanel top=new JPanel(new FlowLayout());top.add(from);top.add(button("⇄",e->{Object x=from.getSelectedItem();from.setSelectedItem(to.getSelectedItem());to.setSelectedItem(x);}));top.add(to);d.add(top,BorderLayout.NORTH);JSplitPane split=new JSplitPane(JSplitPane.VERTICAL_SPLIT,new JScrollPane(in),new JScrollPane(out));split.setResizeWeight(.5);d.add(split,BorderLayout.CENTER);JPanel b=new JPanel();b.add(button("🌐 Google翻訳で開く",e->{openSafeUrl("https://translate.google.com/?sl=auto&tl="+languageCode(String.valueOf(to.getSelectedItem()))+"&text="+URLEncoder.encode(in.getText(),StandardCharsets.UTF_8));}));b.add(button("DeepL",e->openSafeUrl("https://www.deepl.com/translator")));b.add(button("入力をコピー",e->copy(in.getText())));b.add(button("消去",e->{in.setText("");out.setText("");}));d.add(b,BorderLayout.SOUTH);d.setVisible(true);}
    private String languageCode(String name){return switch(name){case "日本語"->"ja";case "英語"->"en";case "中国語"->"zh";case "韓国語"->"ko";case "フランス語"->"fr";case "ドイツ語"->"de";case "スペイン語"->"es";default->"en";};}
    private void openCalculator(){String expr=JOptionPane.showInputDialog(this,"計算式を入力してください（+ - * / と括弧）","NEXUS 電卓",JOptionPane.PLAIN_MESSAGE);if(expr==null||expr.isBlank())return;try{double result=new ExpressionParser(expr).parse();JOptionPane.showMessageDialog(this,expr+" = "+result,"計算結果",JOptionPane.INFORMATION_MESSAGE);}catch(Exception ex){showInfo("式を解析できません: "+ex.getMessage());}}
    private static final class ExpressionParser {private final String s;private int p;ExpressionParser(String s){this.s=s.replace('×','*').replace('÷','/').replace('（','(').replace('）',')');}double parse(){double v=add();ws();if(p<s.length())throw new IllegalArgumentException("余分な文字: "+s.substring(p));if(!Double.isFinite(v))throw new ArithmeticException("無効な値");return v;}double add(){double v=mul();while(true){ws();if(take('+'))v+=mul();else if(take('-'))v-=mul();else return v;}}double mul(){double v=atom();while(true){ws();if(take('*'))v*=atom();else if(take('/')){double n=atom();if(n==0)throw new ArithmeticException("0で除算できません");v/=n;}else return v;}}double atom(){ws();if(take('+'))return atom();if(take('-'))return -atom();if(take('(')){double v=add();ws();if(!take(')'))throw new IllegalArgumentException(") がありません");return v;}int st=p;while(p<s.length()&&(Character.isDigit(s.charAt(p))||s.charAt(p)=='.'))p++;if(st==p)throw new IllegalArgumentException("数値が必要です");return Double.parseDouble(s.substring(st,p));}void ws(){while(p<s.length()&&Character.isWhitespace(s.charAt(p)))p++;}boolean take(char c){if(p<s.length()&&s.charAt(p)==c){p++;return true;}return false;}}

    // Audio
    private void chooseAudio(JLabel label){JFileChooser fc=new JFileChooser();fc.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("WAV / AIFF / AU audio","wav","aiff","aif","au"));if(fc.showOpenDialog(this)==JFileChooser.APPROVE_OPTION){try{stopAudio();audioFile=fc.getSelectedFile().toPath();AudioInputStream ais=AudioSystem.getAudioInputStream(audioFile.toFile());audioClip=AudioSystem.getClip();audioClip.open(ais);label.setText(audioFile.getFileName().toString());}catch(Exception ex){showError("この形式の音声を再生できません。WAV / AIFF / AUを選んでください。",ex);}}}
    private void toggleAudio(){if(audioClip==null){showInfo("先に対応する音声ファイルを選択してください。");return;}if(audioClip.isRunning())audioClip.stop();else audioClip.start();}
    private void stopAudio(){if(audioClip!=null){audioClip.stop();audioClip.setFramePosition(0);}}

    // CodeBridge dialog and simple multi-language line converter
    private void openCodeBridge(){JDialog d=new JDialog(this,"NEXUS CodeBridge + Assistant+ Language Workshop",true);d.setSize(1000,760);d.setLocationRelativeTo(this);JTabbedPane t=new JTabbedPane();
        JPanel convert=new JPanel(new BorderLayout(7,7));JPanel row=new JPanel(new FlowLayout(FlowLayout.LEFT));JComboBox<String> from=new JComboBox<>(new String[]{"JavaScript","TypeScript","Python","Java","Go","C","C++","C#","Rust","PHP","R","BASIC","SQL","HTML"});JComboBox<String> to=new JComboBox<>(new String[]{"Java","Python","JavaScript","TypeScript","C#","C++","Go","Rust","C","R","PHP","BASIC","SQL","HTML"});row.add(new JLabel("変換元"));row.add(from);row.add(new JLabel("変換先"));row.add(to);row.add(button("変換 ↻",e->codeOutput.setText(convertCode(codeInput.getText(),String.valueOf(from.getSelectedItem()),String.valueOf(to.getSelectedItem())))));convert.add(row,BorderLayout.NORTH);
        codeInput=new JTextArea("// ここにコードを入力\nSystem.out.println(\"Hello, NEXUS!\");");codeInput.setFont(new Font(Font.MONOSPACED,Font.PLAIN,13));codeOutput=new JTextArea();codeOutput.setFont(new Font(Font.MONOSPACED,Font.PLAIN,13));JSplitPane split=new JSplitPane(JSplitPane.VERTICAL_SPLIT,new JScrollPane(codeInput),new JScrollPane(codeOutput));split.setResizeWeight(.5);convert.add(split,BorderLayout.CENTER);JPanel cb=new JPanel();cb.add(button("📋 結果をコピー",e->copy(codeOutput.getText())));cb.add(button("⬇ Javaファイル保存",e->saveTextFile("Main.java",codeOutput.getText())));cb.add(button("AI変換依頼文を生成",e->{String prompt="次のコードを"+to.getSelectedItem()+"へ意味・機能を維持して変換してください。\n\n"+codeInput.getText();codeOutput.setText(prompt);}));convert.add(cb,BorderLayout.SOUTH);
        JPanel work=new JPanel(new BorderLayout(6,6));JPanel wr=new JPanel(new FlowLayout(FlowLayout.LEFT));JComboBox<String> lang=new JComboBox<>(new String[]{"Java","Python","JavaScript","TypeScript","C++","C#","Go","Rust"});JTextField name=new JTextField("Main",14);wr.add(lang);wr.add(name);wr.add(button("サンプルを作成",e->workspaceCode.setText(sampleCode(String.valueOf(lang.getSelectedItem())))));wr.add(button("保存",e->saveTextFile(name.getText()+extension(String.valueOf(lang.getSelectedItem())),workspaceCode.getText())));work.add(wr,BorderLayout.NORTH);workspaceCode=new JTextArea();workspaceCode.setFont(new Font(Font.MONOSPACED,Font.PLAIN,13));work.add(new JScrollPane(workspaceCode),BorderLayout.CENTER);work.add(button("ChatGPTに修正を依頼する文章を作成",e->copy("次の"+lang.getSelectedItem()+"コードをレビューし、必要な修正を行ってください。\n"+workspaceCode.getText())),BorderLayout.SOUTH);
        JPanel language=new JPanel(new BorderLayout(6,6));JPanel lf=new JPanel(new GridLayout(2,2,5,5));JTextField lname=new JTextField("NovaScript");JComboBox<String> paradigm=new JComboBox<>(new String[]{"マルチパラダイム","手続き型","オブジェクト指向","関数型","並列処理重視","教育向け"});JComboBox<String> typing=new JComboBox<>(new String[]{"静的型付け（型推論あり）","動的型付け","明示的な静的型付け"});JComboBox<String> syntax=new JComboBox<>(new String[]{"C系（波括弧）","Python風（インデント）","Lisp風（S式）"});lf.add(lname);lf.add(paradigm);lf.add(typing);lf.add(syntax);language.add(lf,BorderLayout.NORTH);languageOutput=new JTextArea();languageOutput.setFont(new Font(Font.MONOSPACED,Font.PLAIN,12));language.add(new JScrollPane(languageOutput),BorderLayout.CENTER);language.add(button("言語仕様を生成",e->languageOutput.setText("# "+lname.getText()+" 言語仕様案\n\nパラダイム: "+paradigm.getSelectedItem()+"\n型システム: "+typing.getSelectedItem()+"\n文法: "+syntax.getSelectedItem()+"\n\n## 基本仕様\n- 変数宣言、関数、条件分岐、反復処理をサポート\n- 明確なエラー表示と安全な標準ライブラリを採用\n- UTF-8を標準文字コードとする\n\n## サンプル\nprint(\"Hello, NEXUS!\")\n")),BorderLayout.SOUTH);
        t.addTab("コード変換",convert);t.addTab("ワークスペース",work);t.addTab("Language Workshop",language);d.add(t);d.setVisible(true);
    }
    private String extension(String lang){return switch(lang){case "Java"->".java";case "Python"->".py";case "JavaScript"->".js";case "TypeScript"->".ts";case "C++"->".cpp";case "C#"->".cs";case "Go"->".go";case "Rust"->".rs";default->".txt";};}
    private String sampleCode(String lang){return switch(lang){case "Java"->"public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, NEXUS!\");\n    }\n}\n";case "Python"->"def main():\n    print(\"Hello, NEXUS!\")\n\nif __name__ == \"__main__\":\n    main()\n";case "C++"->"#include <iostream>\nint main() { std::cout << \"Hello, NEXUS!\" << std::endl; return 0; }\n";case "C#"->"using System;\nclass Program { static void Main() { Console.WriteLine(\"Hello, NEXUS!\"); } }\n";case "Go"->"package main\nimport \"fmt\"\nfunc main() { fmt.Println(\"Hello, NEXUS!\") }\n";case "Rust"->"fn main() { println!(\"Hello, NEXUS!\"); }\n";case "TypeScript"->"const main = (): void => { console.log(\"Hello, NEXUS!\"); };\nmain();\n";default->"console.log(\"Hello, NEXUS!\");\n";};}
    private String convertCode(String source,String from,String to){String f=from.toLowerCase(Locale.ROOT),t=to.toLowerCase(Locale.ROOT);List<String> out=new ArrayList<>();for(String raw:source.split("\\R")){String x=raw.trim();if(x.isEmpty()){out.add("");continue;}String comment=null,expr=null,name=null;Matcher m;
        if(x.startsWith("//")||x.startsWith("#")||x.startsWith("--")){comment=x.replaceFirst("^(//|#|--)\\s*","");}
        if(comment!=null){out.add(switch(t){case "python","r","php"->"# "+comment;case "sql"->"-- "+comment;default->"// "+comment;});continue;}
        String[] patterns=switch(f){case "java"->new String[]{"^System\\.out\\.println\\((.*)\\);?$","^(?:String|int|double|boolean|var)\\s+(\\w+)\\s*=\\s*(.+?);?$"};case "python"->new String[]{"^print\\((.*)\\)$","^(\\w+)\\s*=\\s*(.+)$"};case "javascript","typescript"->new String[]{"^console\\.log\\((.*)\\);?$","^(?:let|const|var)\\s+(\\w+)(?:\\s*:\\s*\\w+)?\\s*=\\s*(.+?);?$"};case "c#"->new String[]{"^Console\\.WriteLine\\((.*)\\);?$","^(?:string|int|double|bool|var)\\s+(\\w+)\\s*=\\s*(.+?);?$"};case "c++"->new String[]{"^(?:std::)?cout\\s*<<\\s*(.*?)\\s*(?:<<\\s*std::endl)?;?$","^(?:int|double|float|bool|std::string)\\s+(\\w+)\\s*=\\s*(.+?);?$"};case "go"->new String[]{"^fmt\\.Println\\((.*)\\)$","^(?:var\\s+)?(\\w+)\\s*(?::=|=)\\s*(.+)$"};case "rust"->new String[]{"^println!\\((.*)\\);?$","^let\\s+(?:mut\\s+)?(\\w+)\\s*=\\s*(.+?);?$"};default->new String[]{"^print\\((.*)\\)$","^(\\w+)\\s*=\\s*(.+)$"};};
        m=Pattern.compile(patterns[0]).matcher(x);if(m.matches()){expr=m.group(1);out.add(emitPrint(expr,t));continue;}m=Pattern.compile(patterns[1]).matcher(x);if(m.matches()){name=m.group(1);expr=m.group(2);out.add(emitVar(name,expr,t));continue;}if(x.startsWith("<!DOCTYPE")||x.startsWith("<html")||x.startsWith("<p")){out.add(t.equals("html")?x:"// HTML markup requires manual conversion: "+x);continue;}out.add(switch(t){case "python","r"->"# REVIEW: "+x;case "sql"->"-- REVIEW: "+x;default->"// REVIEW: "+x;});}
        String body=String.join("\n",out);if(t.equals("java")){return "public class Main {\n    public static void main(String[] args) {\n"+indent(body,"        ")+"\n    }\n}\n";}if(t.equals("c#"))return "using System;\nclass Program { static void Main() {\n"+indent(body,"    ")+"\n} }\n";if(t.equals("go"))return "package main\nimport \"fmt\"\nfunc main() {\n"+indent(body,"    ")+"\n}\n";if(t.equals("python"))return "# NEXUS CodeBridge output — review before execution\n"+body+"\n";if(t.equals("rust"))return "fn main() {\n"+indent(body,"    ")+"\n}\n";return "// NEXUS CodeBridge output — review before execution\n"+body+"\n";}
    private String indent(String s,String pad){return Arrays.stream(s.split("\\R",-1)).map(x->pad+x).reduce((a,b)->a+"\n"+b).orElse("");}
    private String emitPrint(String x,String to){String e=x.trim();return switch(to){case "java"->"System.out.println("+e+");";case "python","r"->"print("+e+")";case "javascript","typescript"->"console.log("+e+");";case "c#"->"Console.WriteLine("+e+");";case "c++"->"std::cout << "+e+" << std::endl;";case "go"->"fmt.Println("+e+")";case "rust"->"println!(\"{}\", "+e+");";case "php"->"echo "+e+";";case "basic"->"PRINT "+e;case "sql"->"SELECT "+e+" AS output;";default->"print("+e+")";};}
    private String emitVar(String name,String expr,String to){String e=expr.trim();String type=e.startsWith("\"")||e.startsWith("'")?"str":e.equals("true")||e.equals("false")?"bool":e.matches("-?\\d+")?"int":e.matches("-?[0-9.]+")?"float":"var";return switch(to){case "java"->(type.equals("str")?"String":type.equals("bool")?"boolean":type.equals("float")?"double":"var")+" "+name+" = "+e+";";case "python","javascript","typescript","r"->name+" = "+e;case "c#"->(type.equals("str")?"string":type.equals("bool")?"bool":type.equals("float")?"double":"var")+" "+name+" = "+e+";";case "go"->name+" := "+e;case "rust"->"let "+name+" = "+e+";";case "php"->"$"+name+" = "+e+";";case "basic"->"LET "+name+" = "+e;case "sql"->"SELECT "+e+" AS "+name+";";default->name+" = "+e;};}

    // Board records
    private void openBoard(){JDialog d=new JDialog(this,"NEXUS 掲示板記録",true);d.setSize(920,650);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(8,8));boardModel.clear();boardIds.clear();List<String[]> rows=readRows("board",6);rows.sort((a,b)->b[4].compareTo(a[4]));int i=0;for(String[]r:rows){boardModel.addElement("["+r[1]+"] "+r[2]+"  ·  "+r[4]);boardIds.put(i++,r[0]);}
        boardList=new JList<>(boardModel);boardTitle=new JTextField();boardBody=new JTextArea();boardBody.setLineWrap(true);boardBody.setWrapStyleWord(true);boardType=new JComboBox<>(new String[]{"主の最近の感想","近況・日記","お知らせ","アイデア・ひらめき"});JPanel edit=new JPanel(new BorderLayout(5,5));JPanel fields=new JPanel(new GridLayout(2,1,4,4));fields.add(boardType);fields.add(boardTitle);edit.add(fields,BorderLayout.NORTH);edit.add(new JScrollPane(boardBody),BorderLayout.CENTER);JPanel tools=new JPanel();tools.add(button("💾 保存",e->{String title=boardTitle.getText().trim(),body=boardBody.getText();if(title.isEmpty()||body.isBlank()){showInfo("タイトルと本文を入力してください。");return;}List<String[]>r=readRows("board",6);r.add(new String[]{UUID.randomUUID().toString(),String.valueOf(boardType.getSelectedItem()),title,body,LocalDateTime.now().toString(),""});writeRows("board",r);d.dispose();openBoard();}));tools.add(button("⬇ TXT保存",e->exportRows("NEXUS-掲示板.txt",readRows("board",6))));tools.add(button("＋ 新規",e->{boardList.clearSelection();boardTitle.setText("");boardBody.setText("");}));edit.add(tools,BorderLayout.SOUTH);boardList.addListSelectionListener(e->{int ix=boardList.getSelectedIndex();if(ix>=0){String id=boardIds.get(ix);for(String[]r:readRows("board",6))if(r[0].equals(id)){boardType.setSelectedItem(r[1]);boardTitle.setText(r[2]);boardBody.setText(r[3]);}}});d.add(new JSplitPane(JSplitPane.HORIZONTAL_SPLIT,new JScrollPane(boardList),edit),BorderLayout.CENTER);d.add(button("閉じる",e->d.dispose()),BorderLayout.SOUTH);d.setVisible(true);}

    // Drawing Studio with undo and PNG export
    private void openDrawing(){JDialog d=new JDialog(this,"NEXUS お絵かきスタジオ",true);d.setSize(1000,720);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(6,6));drawPanel=new DrawPanel();JPanel tools=new JPanel(new FlowLayout(FlowLayout.LEFT));JComboBox<String> tool=new JComboBox<>(new String[]{"ペン","蛍光","ネオン","消しゴム","直線","四角","円","文字"});JColorChooser color=new JColorChooser(Color.BLUE);JSpinner width=new JSpinner(new SpinnerNumberModel(5,1,60,1));tools.add(new JLabel("ツール"));tools.add(tool);tools.add(new JLabel("色"));tools.add(button("色を選択",e->{Color c=JColorChooser.showDialog(d,"描画色",drawPanel.color);if(c!=null)drawPanel.color=c;}));tools.add(new JLabel("太さ"));tools.add(width);tools.add(button("↩ Undo",e->drawPanel.undo()));tools.add(button("消去",e->drawPanel.clear()));tools.add(button("PNG保存",e->saveDrawing()));tools.add(button("閉じる",e->d.dispose()));tool.addActionListener(e->drawPanel.tool=String.valueOf(tool.getSelectedItem()));width.addChangeListener(e->drawPanel.stroke=((Number)width.getValue()).floatValue());d.add(tools,BorderLayout.NORTH);d.add(new JScrollPane(drawPanel),BorderLayout.CENTER);d.setVisible(true);}
    private void saveDrawing(){if(drawPanel==null)return;JFileChooser fc=new JFileChooser();fc.setSelectedFile(new File("NEXUS-drawing.png"));if(fc.showSaveDialog(this)==JFileChooser.APPROVE_OPTION){try{ImageIO.write(drawPanel.image,"png",fc.getSelectedFile());showInfo("PNGを保存しました。");}catch(Exception ex){showError("PNG保存に失敗しました",ex);}}}
    private class DrawPanel extends JPanel {BufferedImage image=new BufferedImage(1200,700,BufferedImage.TYPE_INT_ARGB);Deque<BufferedImage> undo=new ArrayDeque<>();Color color=Color.BLUE;float stroke=5;String tool="ペン";Point start,last;DrawPanel(){setPreferredSize(new Dimension(1200,700));setBackground(Color.WHITE);Graphics2D g=image.createGraphics();g.setColor(Color.WHITE);g.fillRect(0,0,1200,700);g.dispose();addMouseListener(new MouseAdapter(){public void mousePressed(MouseEvent e){push();start=scale(e.getPoint());last=start;if(tool.equals("文字")){String t=JOptionPane.showInputDialog(DrawPanel.this,"描画する文字");if(t!=null){Graphics2D g=image.createGraphics();g.setColor(color);g.setFont(new Font("SansSerif",Font.BOLD,36));g.drawString(t,start.x,start.y);g.dispose();repaint();}}}public void mouseReleased(MouseEvent e){if(start!=null&&!tool.equals("ペン")&&!tool.equals("蛍光")&&!tool.equals("ネオン")&&!tool.equals("消しゴム")&&!tool.equals("文字")){Graphics2D g=image.createGraphics();g.setColor(color);g.setStroke(new BasicStroke(stroke));Point end=scale(e.getPoint());int x=Math.min(start.x,end.x),y=Math.min(start.y,end.y),w=Math.abs(end.x-start.x),h=Math.abs(end.y-start.y);switch(tool){case "直線"->g.drawLine(start.x,start.y,end.x,end.y);case "四角"->g.drawRect(x,y,w,h);case "円"->g.drawOval(x,y,w,h);}g.dispose();}start=null;repaint();}});addMouseMotionListener(new MouseMotionAdapter(){public void mouseDragged(MouseEvent e){Point p=scale(e.getPoint());if(start==null)return;if(tool.equals("ペン")||tool.equals("蛍光")||tool.equals("ネオン")||tool.equals("消しゴム")){Graphics2D g=image.createGraphics();float alpha=tool.equals("蛍光")?.28f:1f;g.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER,alpha));g.setStroke(new BasicStroke(tool.equals("消しゴム")?stroke*4:stroke,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND));g.setColor(tool.equals("消しゴム")?Color.WHITE:color);if(tool.equals("ネオン")){g.setColor(color);g.setComposite(AlphaComposite.SrcOver);g.setStroke(new BasicStroke(stroke+8,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND));g.setColor(new Color(color.getRed(),color.getGreen(),color.getBlue(),70));g.drawLine(last.x,last.y,p.x,p.y);g.setColor(color);g.setStroke(new BasicStroke(stroke,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND));}g.drawLine(last.x,last.y,p.x,p.y);g.dispose();last=p;repaint();}}});}Point scale(Point p){return new Point(Math.max(0,Math.min(1199,p.x*1200/Math.max(1,getWidth()))),Math.max(0,Math.min(699,p.y*700/Math.max(1,getHeight()))));}void push(){BufferedImage copy=new BufferedImage(1200,700,image.getType());Graphics2D g=copy.createGraphics();g.drawImage(image,0,0,null);g.dispose();undo.push(copy);if(undo.size()>16)undo.removeLast();}void undo(){if(!undo.isEmpty()){image=undo.pop();repaint();}}void clear(){push();Graphics2D g=image.createGraphics();g.setColor(Color.WHITE);g.fillRect(0,0,1200,700);g.dispose();repaint();}protected void paintComponent(Graphics g){super.paintComponent(g);g.drawImage(image,0,0,getWidth(),getHeight(),null);}}

    // Garbling lab
    private void openGarbler(){JDialog d=new JDialog(this,"NEXUS 文字化けラボ",true);d.setSize(760,600);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(6,6));JTextArea in=new JTextArea(),out=new JTextArea();in.setLineWrap(true);out.setLineWrap(true);out.setEditable(false);JPanel north=new JPanel(new FlowLayout());JComboBox<String> mode=new JComboBox<>(new String[]{"文字化け風","記号ノイズ","逆順","Base64エンコード","Base64デコード"});north.add(mode);north.add(button("変換",e->{String s=in.getText();String m=String.valueOf(mode.getSelectedItem());try{String v=switch(m){case "逆順"->new StringBuilder(s).reverse().toString();case "Base64エンコード"->Base64.getEncoder().encodeToString(s.getBytes(StandardCharsets.UTF_8));case "Base64デコード"->new String(Base64.getDecoder().decode(s),StandardCharsets.UTF_8);case "記号ノイズ"->noise(s);default->garble(s);};out.setText(v);}catch(Exception ex){out.setText("変換できません: "+ex.getMessage());}}));JSplitPane sp=new JSplitPane(JSplitPane.VERTICAL_SPLIT,new JScrollPane(in),new JScrollPane(out));sp.setResizeWeight(.5);d.add(north,BorderLayout.NORTH);d.add(sp,BorderLayout.CENTER);JPanel b=new JPanel();b.add(button("コピー",e->copy(out.getText())));b.add(button("閉じる",e->d.dispose()));d.add(b,BorderLayout.SOUTH);d.setVisible(true);}
    private String garble(String s){StringBuilder b=new StringBuilder();String[] marks={"縺","繧","�","�","∴","▒","▓","◈","※"};Random r=new Random();for(char c:s.toCharArray()){if(c=='\n'||c=='\r'||r.nextDouble()>.45)b.append(c);else b.append(marks[r.nextInt(marks.length)]);}return b.toString();}
    private String noise(String s){StringBuilder b=new StringBuilder(s);Random r=new Random();for(int i=0;i<Math.min(300,Math.max(10,s.length()/2));i++)b.insert(r.nextInt(b.length()+1),"※▒░∴◈".charAt(r.nextInt(5)));return b.toString();}

    // URL checker and security report
    private void openUrlChecker(){String input=JOptionPane.showInputDialog(this,"検査したいURL（外部へ送信せずローカル分析）","https://example.com/");if(input==null||input.isBlank())return;String report=checkUrl(input);JTextArea area=new JTextArea(report,18,64);area.setEditable(false);area.setLineWrap(true);area.setWrapStyleWord(true);JOptionPane.showMessageDialog(this,new JScrollPane(area),"NEXUS URLチェッカー",JOptionPane.INFORMATION_MESSAGE);}
    private String checkUrl(String raw){StringBuilder b=new StringBuilder();int score=0;URI u;try{String x=raw.trim();if(!x.matches("^[a-zA-Z][a-zA-Z0-9+.-]*://.*"))x="https://"+x;u=new URI(x);if(u.getHost()==null)throw new Exception("ホスト名を解析できません");}catch(Exception e){return "URL形式: 不正\n詳細: "+e.getMessage();}String host=u.getHost().toLowerCase(Locale.ROOT);b.append("URL: ").append(u).append("\nホスト: ").append(host).append("\nプロトコル: ").append(u.getScheme()).append("\n\n検出項目:\n");if(!"https".equalsIgnoreCase(u.getScheme())){score+=25;b.append("[注意] HTTPSではありません。\n");}else b.append("[OK] HTTPSを使用しています。\n");if(u.getUserInfo()!=null){score+=30;b.append("[警告] URLにユーザー情報が含まれます。\n");}if(host.matches("[0-9.]+")||host.contains(":")){score+=20;b.append("[注意] IPアドレス形式のホストです。\n");}if(host.contains("xn--")){score+=20;b.append("[注意] 国際化ドメイン（Punycode）が含まれます。\n");}if(host.split("\\.").length>5){score+=10;b.append("[注意] サブドメイン階層が深いです。\n");}if(host.matches(".*(login|verify|secure|account|wallet|update).*")){score+=8;b.append("[情報] 認証を連想させる単語が含まれます。\n");}if(host.matches(".*(bit\\.ly|tinyurl\\.com|t\\.co|goo\\.gl|is\\.gd).*")){score+=18;b.append("[注意] URL短縮サービスの可能性があります。\n");}if((u.getRawQuery()+u.getPath()).matches("(?i).*(password|passwd|token|session|apikey|secret)=.*")){score+=15;b.append("[警告] URLに機密情報らしいパラメータが含まれる可能性があります。\n");}if(u.getRawPath()!=null&&u.getRawPath().length()>180){score+=5;b.append("[情報] パスが長いです。\n");}if(score==0)b.append("[OK] 簡易ルールで目立つ注意項目は見つかりませんでした。\n");b.append("\n形式上の注意度: ").append(Math.min(100,score)).append(" / 100\n");b.append("注意: この数値はURL文字列だけのルールベース判定です。Webサイトの安全性・運営者・マルウェア感染を確認したものではありません。URLを自動で開いたり外部送信したりしません。");return b.toString();}
    private String securityReport(){StringBuilder b=new StringBuilder("NEXUS SUPER 4.1 — ローカルセキュリティレポート\n生成: ").append(LocalDateTime.now()).append("\n\n");int ok=0,warn=0;String[][]checks={{"Java runtime",System.getProperty("java.version")},{"ローカル保存フォルダー",Files.exists(DATA_DIR)?"存在":"未作成"},{"自動天気通信",autoWeather?"許可（注意）":"停止（OK）"},{"通信匿名モード",anonymousMode?"有効":"無効"},{"画面プライバシー",privacyBlur?"有効":"無効"},{"画面保護",screenProtect?"有効":"無効"},{"外部通信", "天気取得・速度測定を除き自動通信なし"}};for(String[]c:checks){boolean w=c[0].equals("自動天気通信")&&autoWeather;b.append(w?"[注意] ":"[確認] ").append(c[0]).append(": ").append(c[1]).append('\n');if(w)warn++;else ok++;}b.append("\n確認 ").append(ok).append(" / 注意 ").append(warn).append("\n\n");b.append("このJava版の診断はアプリ設定の確認です。OS全体の脆弱性診断、ウイルス検査、通信傍受、侵入検知は行いません。\n");try{b.append("保存ファイルサイズ: ").append(Files.exists(DATA_FILE)?Files.size(DATA_FILE):0).append(" bytes\n");}catch(Exception ignored){}return b.toString();}
    private void openSecurityReport(){JTextArea a=new JTextArea(securityReport(),24,75);a.setEditable(false);a.setForeground(TEXT);a.setBackground(PANEL);JOptionPane.showMessageDialog(this,new JScrollPane(a),"🛡 セキュリティ・プライバシーレポート",JOptionPane.INFORMATION_MESSAGE);}

    // Backup / restore, optionally AES-256-GCM
    private void exportBackup(){JFileChooser fc=new JFileChooser();fc.setSelectedFile(new File("NEXUS-backup-"+LocalDate.now()+".nxbackup"));if(fc.showSaveDialog(this)!=JFileChooser.APPROVE_OPTION)return;JCheckBox enc=new JCheckBox("AES-256-GCMで暗号化する（推奨）",true);JPasswordField pass=new JPasswordField(18);JPanel panel=new JPanel(new GridLayout(0,1));panel.add(enc);panel.add(new JLabel("暗号化パスフレーズ（暗号化時のみ）"));panel.add(pass);if(JOptionPane.showConfirmDialog(this,panel,"バックアップ設定",JOptionPane.OK_CANCEL_OPTION)!=JOptionPane.OK_OPTION)return;try{ByteArrayOutputStream bos=new ByteArrayOutputStream();data.store(bos,"NEXUS backup");byte[] content=bos.toByteArray();if(enc.isSelected()){if(pass.getPassword().length<8)throw new IllegalArgumentException("パスフレーズは8文字以上にしてください。");content=encrypt(content,pass.getPassword());}Files.write(fc.getSelectedFile().toPath(),content);showInfo("バックアップを保存しました。個人データを含むため安全に保管してください。");}catch(Exception ex){showError("バックアップを作成できませんでした",ex);}}
    private void importBackup(){JFileChooser fc=new JFileChooser();if(fc.showOpenDialog(this)!=JFileChooser.APPROVE_OPTION)return;try{byte[] content=Files.readAllBytes(fc.getSelectedFile().toPath());if(content.length>40*1024*1024)throw new IOException("ファイルが大きすぎます。");if(startsWith(content,"NEXUSENC1")){JPasswordField pass=new JPasswordField(18);if(JOptionPane.showConfirmDialog(this,pass,"復号パスフレーズ",JOptionPane.OK_CANCEL_OPTION)!=JOptionPane.OK_OPTION)return;content=decrypt(content,pass.getPassword());}Properties incoming=new Properties();incoming.load(new ByteArrayInputStream(content));if(JOptionPane.showConfirmDialog(this,"現在のNEXUSデータを読み込みデータで置き換えますか？\n現在のデータは自動退避されません。先にエクスポートしてください。","復元確認",JOptionPane.YES_NO_OPTION)!=JOptionPane.YES_OPTION)return;data.clear();data.putAll(incoming);saveData();loadSettings();showInfo("復元しました。設定反映のためアプリを再起動してください。");}catch(Exception ex){showError("バックアップを読み込めませんでした",ex);}}
    private byte[] encrypt(byte[] plain,char[] password)throws Exception{byte[]salt=new byte[16],iv=new byte[12];SecureRandom r=new SecureRandom();r.nextBytes(salt);r.nextBytes(iv);SecretKeyFactory f=SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");SecretKey tmp=f.generateSecret(new PBEKeySpec(password,salt,210000,256));SecretKeySpec key=new SecretKeySpec(tmp.getEncoded(),"AES");Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.ENCRYPT_MODE,key,new GCMParameterSpec(128,iv));byte[]cipher=c.doFinal(plain);ByteArrayOutputStream out=new ByteArrayOutputStream();out.write("NEXUSENC1".getBytes(StandardCharsets.US_ASCII));out.write(salt);out.write(iv);out.write(cipher);return out.toByteArray();}
    private byte[] decrypt(byte[] all,char[] password)throws Exception{if(all.length<37)throw new IOException("暗号化データが不完全です。");byte[]salt=Arrays.copyOfRange(all,9,25),iv=Arrays.copyOfRange(all,25,37),cipher=Arrays.copyOfRange(all,37,all.length);SecretKeyFactory f=SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");SecretKey tmp=f.generateSecret(new PBEKeySpec(password,salt,210000,256));Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.DECRYPT_MODE,new SecretKeySpec(tmp.getEncoded(),"AES"),new GCMParameterSpec(128,iv));return c.doFinal(cipher);}
    private boolean startsWith(byte[]a,String s){byte[]p=s.getBytes(StandardCharsets.US_ASCII);if(a.length<p.length)return false;for(int i=0;i<p.length;i++)if(a[i]!=p[i])return false;return true;}

    // Settings, screen protection, sleep restriction, developer tools
    private void openSettings(){JDialog d=new JDialog(this,"NEXUS カスタマイズ・プライバシー",true);d.setSize(650,560);d.setLocationRelativeTo(this);d.setLayout(new BorderLayout(6,6));JPanel p=new JPanel();p.setLayout(new BoxLayout(p,BoxLayout.Y_AXIS));JColorChooser chooser=new JColorChooser(accent);chooser.setPreviewPanel(new JPanel());p.add(new JLabel("アクセントカラー"));p.add(chooser);JCheckBox auto=new JCheckBox("天気の自動取得を許可",autoWeather),anon=new JCheckBox("通信匿名モード",anonymousMode),blur=new JCheckBox("フォーカスを失ったときに保護表示",privacyBlur),protect=new JCheckBox("画面保護モード",screenProtect),fast=new JCheckBox("高速・軽量モード",fastMode),reduce=new JCheckBox("アニメーションを抑制",reducedMotion),outline=new JCheckBox("要素境界を表示（診断用）",debugOutline);for(JCheckBox c:List.of(auto,anon,blur,protect,fast,reduce,outline)){styleCheck(c);p.add(c);}JComboBox<String> wallpaper=new JComboBox<>(new String[]{"落ち着いた背景","宇宙空間","深宇宙ブルー","ネオングリッド"});wallpaper.setSelectedItem(get("setting.wallpaper","宇宙空間"));p.add(new JLabel("背景スタイル"));p.add(wallpaper);d.add(new JScrollPane(p),BorderLayout.CENTER);JPanel b=new JPanel();b.add(button("適用・保存",e->{accent=chooser.getColor();autoWeather=auto.isSelected();anonymousMode=anon.isSelected();privacyBlur=blur.isSelected();screenProtect=protect.isSelected();fastMode=fast.isSelected();reducedMotion=reduce.isSelected();debugOutline=outline.isSelected();put("setting.accent",String.format("#%02x%02x%02x",accent.getRed(),accent.getGreen(),accent.getBlue()));putBool("setting.autoWeather",autoWeather);putBool("setting.anonymous",anonymousMode);putBool("setting.privacyBlur",privacyBlur);putBool("setting.screenProtect",screenProtect);putBool("setting.fast",fastMode);putBool("setting.reducedMotion",reducedMotion);putBool("setting.debugOutline",debugOutline);put("setting.wallpaper",String.valueOf(wallpaper.getSelectedItem()));d.dispose();showInfo("設定を保存しました。");}));b.add(button("閉じる",e->d.dispose()));d.add(b,BorderLayout.SOUTH);d.setVisible(true);}
    private void activateScreenProtect(){JDialog d=new JDialog(this,"NEXUS 画面保護",true);d.setUndecorated(true);d.setBackground(new Color(0,0,0,230));JPanel p=new JPanel(new GridBagLayout());p.setBackground(new Color(3,8,24));JLabel l=new JLabel("🔒 画面プライバシー保護中");l.setForeground(Color.WHITE);l.setFont(l.getFont().deriveFont(Font.BOLD,28f));JButton b=button("画面に戻る",e->d.dispose());JPanel inner=new JPanel(new GridLayout(2,1,5,20));inner.setOpaque(false);inner.add(l);inner.add(b);p.add(inner);d.setContentPane(p);d.setSize(getSize());d.setLocationRelativeTo(this);d.setVisible(true);}
    private void openSleepSettings(){JDialog d=new JDialog(this,"NEXUS おやすみ制限",true);d.setSize(480,300);d.setLocationRelativeTo(this);JPanel p=new JPanel(new GridLayout(0,2,7,7));JCheckBox enabled=new JCheckBox("制限を有効にする",sleepEnabled);JSpinner start=new JSpinner(new SpinnerDateModel()),end=new JSpinner(new SpinnerDateModel());start.setEditor(new JSpinner.DateEditor(start,"HH:mm"));end.setEditor(new JSpinner.DateEditor(end,"HH:mm"));start.setValue(Date.from(LocalDate.now().atTime(sleepStart).atZone(ZoneId.systemDefault()).toInstant()));end.setValue(Date.from(LocalDate.now().atTime(sleepEnd).atZone(ZoneId.systemDefault()).toInstant()));p.add(enabled);p.add(new JLabel("指定した時間帯に休憩画面を表示"));p.add(new JLabel("開始時刻"));p.add(start);p.add(new JLabel("終了時刻"));p.add(end);JPanel b=new JPanel();b.add(button("💾 保存",e->{sleepEnabled=enabled.isSelected();sleepStart=((Date)start.getValue()).toInstant().atZone(ZoneId.systemDefault()).toLocalTime();sleepEnd=((Date)end.getValue()).toInstant().atZone(ZoneId.systemDefault()).toLocalTime();putBool("setting.sleepEnabled",sleepEnabled);put("setting.sleepStart",sleepStart.toString());put("setting.sleepEnd",sleepEnd.toString());d.dispose();}));b.add(button("🌙 1分テスト",e->{d.dispose();sleepTest=true;activateSleepOverlay();new javax.swing.Timer(60_000,x->{sleepTest=false;((javax.swing.Timer)x.getSource()).stop();}).start();}));b.add(button("閉じる",e->d.dispose()));d.add(p,BorderLayout.CENTER);d.add(b,BorderLayout.SOUTH);d.setVisible(true);}
    private void startSleepMonitor(){new javax.swing.Timer(15_000,e->{if((sleepEnabled&&sleepActive())||sleepTest){if(!sleepTest)activateSleepOverlay();}}).start();}
    private boolean sleepActive(){LocalTime n=LocalTime.now();if(sleepStart.equals(sleepEnd))return false;if(sleepStart.isBefore(sleepEnd))return !n.isBefore(sleepStart)&&n.isBefore(sleepEnd);return !n.isBefore(sleepStart)||n.isBefore(sleepEnd);}
    private void activateSleepOverlay(){if(!isShowing()||sleepOverlayOpen)return;sleepOverlayOpen=true;JDialog d=new JDialog(this,"おやすみ制限中",true);d.setSize(520,300);d.setLocationRelativeTo(this);JPanel p=new JPanel(new GridLayout(0,1,10,10));p.setBackground(new Color(10,20,38));JLabel label=new JLabel("☾ おやすみ制限中",SwingConstants.CENTER);label.setForeground(Color.WHITE);label.setFont(label.getFont().deriveFont(Font.BOLD,28f));JLabel msg=new JLabel("設定した時間帯です。画面から離れて休憩しましょう。",SwingConstants.CENTER);msg.setForeground(TEXT);p.add(label);p.add(msg);p.add(button("設定画面へ",e->{d.dispose();openSleepSettings();}));if(sleepTest)p.add(button("テストを終了",e->{sleepTest=false;d.dispose();}));d.setContentPane(p);d.addWindowListener(new WindowAdapter(){@Override public void windowClosed(WindowEvent e){sleepOverlayOpen=false;}@Override public void windowClosing(WindowEvent e){sleepOverlayOpen=false;}});d.setVisible(true);sleepOverlayOpen=false;}

    private void openDeveloper(){if(!developerEnabled){int yes=JOptionPane.showConfirmDialog(this,"開発者モードを有効にしますか？\n診断・ローカル保存データの表示と編集機能があります。","開発者モード",JOptionPane.YES_NO_OPTION,JOptionPane.WARNING_MESSAGE);if(yes!=JOptionPane.YES_OPTION)return;developerEnabled=true;putBool("setting.developer",true);}JDialog d=new JDialog(this,"NEXUS 開発者モード・管理センター",true);d.setSize(900,680);d.setLocationRelativeTo(this);JTabbedPane tabs=new JTabbedPane();
        developerOutput=new JTextArea("診断を実行してください。");developerOutput.setEditable(false);JPanel diagnostics=new JPanel(new BorderLayout(6,6));diagnostics.add(new JScrollPane(developerOutput),BorderLayout.CENTER);JPanel db=new JPanel();db.add(button("🔍 診断を再実行",e->developerOutput.setText(securityReport()+"\n"+systemSummary())));db.add(button("⬇ レポート保存",e->saveTextFile("NEXUS-diagnostics.txt",developerOutput.getText())));db.add(button("開発者モードを停止",e->{developerEnabled=false;adminEnabled=false;putBool("setting.developer",false);d.dispose();}));diagnostics.add(db,BorderLayout.SOUTH);
        JPanel admin=new JPanel(new BorderLayout(6,6));JButton grant=button("🛡 管理者権限をこのセッションで有効化",e->{adminEnabled=true;JOptionPane.showMessageDialog(d,"管理者権限を有効にしました。アプリ内の保存データを変更できます。");});JTextArea adminInfo=new JTextArea("管理コマンド（許可リスト）:\nhelp / status / keys / fast on|off / privacy on|off / network on|off / reset-ui\n\n任意Javaコード・OSシェルは実行しません。");adminInfo.setEditable(false);adminInfo.setBackground(PANEL);adminInfo.setForeground(TEXT);JTextField command=new JTextField();JTextArea output=new JTextArea();output.setEditable(false);JPanel cp=new JPanel(new BorderLayout(4,4));cp.add(command,BorderLayout.CENTER);cp.add(button("実行",e->runAdminCommand(command.getText(),output)),BorderLayout.EAST);admin.add(grant,BorderLayout.NORTH);admin.add(adminInfo,BorderLayout.CENTER);admin.add(cp,BorderLayout.SOUTH);
        JPanel storage=new JPanel(new BorderLayout(5,5));JList<String> keys=new JList<>(data.stringPropertyNames().stream().sorted().toArray(String[]::new));JTextArea value=new JTextArea();value.setEditable(false);keys.addListSelectionListener(e->{if(!e.getValueIsAdjusting()&&keys.getSelectedValue()!=null)value.setText(data.getProperty(keys.getSelectedValue(),""));});storage.add(new JScrollPane(keys),BorderLayout.WEST);storage.add(new JScrollPane(value),BorderLayout.CENTER);JPanel sb=new JPanel();sb.add(button("値を編集・保存",e->{if(!adminEnabled){showInfo("先に管理者権限を有効化してください。");return;}String key=keys.getSelectedValue();if(key!=null){data.setProperty(key,value.getText());saveData();showInfo("保存しました。");}}));sb.add(button("キー削除",e->{if(!adminEnabled){showInfo("先に管理者権限を有効化してください。");return;}String key=keys.getSelectedValue();if(key!=null){data.remove(key);saveData();showInfo("削除しました。画面を開き直すと一覧が更新されます。");}}));storage.add(sb,BorderLayout.SOUTH);
        tabs.addTab("診断",diagnostics);tabs.addTab("管理コマンド",admin);tabs.addTab("保存データ",storage);d.add(tabs);d.setVisible(true);}
    private void runAdminCommand(String raw,JTextArea out){if(!adminEnabled){out.setText("管理者権限が必要です。");return;}String[]p=raw.trim().toLowerCase(Locale.ROOT).split("\\s+");String result=switch(p[0]){case "help"->"help, status, keys, fast on|off, privacy on|off, network on|off, reset-ui";case "status"->systemSummary();case "keys"->String.join("\n",data.stringPropertyNames().stream().sorted().toList());case "fast"->{if(p.length>1){fastMode=p[1].equals("on");putBool("setting.fast",fastMode);}yield "fast="+fastMode;}case "privacy"->{if(p.length>1){anonymousMode=p[1].equals("on");putBool("setting.anonymous",anonymousMode);}yield "anonymous="+anonymousMode;}case "network"->{if(p.length>1){autoWeather=p[1].equals("on");putBool("setting.autoWeather",autoWeather);}yield "autoWeather="+autoWeather;}case "reset-ui"->{yield "UI設定を初期化するにはカスタマイズ画面を開いてください。";}default->"不明なコマンドです。help を入力してください。";};out.setText(result);}

    private void openCommandPalette(){String q=JOptionPane.showInputDialog(this,"起動する機能名を入力（Todo / メモ / 天気 / CodeBridge / セキュリティ / URL）","NEXUS COMMAND PALETTE");if(q==null)return;String x=q.toLowerCase(Locale.ROOT);if(x.contains("todo"))openProductivityTab("Todo");else if(x.contains("メモ")||x.contains("memo"))openProductivityTab("メモ");else if(x.contains("天気"))loadWeather(true);else if(x.contains("code"))openCodeBridge();else if(x.contains("url"))openUrlChecker();else if(x.contains("security")||x.contains("セキュリティ"))openSecurityReport();else if(x.contains("絵")||x.contains("draw"))openDrawing();else if(x.contains("予定"))openProductivityTab("予定表");else if(x.contains("文字化け"))openGarbler();else showInfo("一致する機能がありません。");}
    private void openProductivityTab(String name){for(Component c:getContentPane().getComponents())if(c instanceof JPanel root){for(Component cc:root.getComponents())if(cc instanceof JTabbedPane tabs){tabs.setSelectedIndex(1);showInfo(name+"は「日常ツール」タブにあります。");return;}}}
    private void openNews(){JDialog d=new JDialog(this,"今日のニュース",true);d.setSize(540,500);d.setLocationRelativeTo(this);JPanel p=new JPanel();p.setLayout(new BoxLayout(p,BoxLayout.Y_AXIS));p.add(new JLabel("📰 ニュース配信元（見出しは各サイトで確認）"));String[][]links={{"NHK","https://www3.nhk.or.jp/news/"},{"Yahoo!ニュース","https://news.yahoo.co.jp/"},{"Googleニュース","https://news.google.com/"},{"神戸新聞","https://www.kobe-np.co.jp/"},{"ITmedia NEWS","https://www.itmedia.co.jp/news/"},{"Reuters","https://www.reuters.com/"}};for(String[]x:links){JButton b=button(x[0]+" ↗",e->openSafeUrl(x[1]));b.setAlignmentX(Component.LEFT_ALIGNMENT);p.add(b);}d.add(new JScrollPane(p));d.setVisible(true);}

    // Assistant local commands
    private void handleAssistant(JTextArea conversation){String raw=assistantInput.getText().trim();if(raw.isEmpty())return;assistantInput.setText("");String answer="";String low=raw.toLowerCase(Locale.ROOT);if(raw.startsWith("メモ:")||raw.startsWith("メモ：")){String text=raw.substring(3).trim();List<String[]>r=readRows("memos",5);r.add(new String[]{UUID.randomUUID().toString(),"Assistant+メモ",text,"false",Instant.now().toString()});writeRows("memos",r);answer="メモに保存しました。";}else if(raw.startsWith("Todo:")||raw.startsWith("Todo：")){String text=raw.substring(5).trim();List<String[]>r=readRows("todo."+LocalDate.now(),3);r.add(new String[]{UUID.randomUUID().toString(),text,"false"});writeRows("todo."+LocalDate.now(),r);answer="今日のTodoに追加しました。";}else if(raw.startsWith("予定 ")){String[]parts=raw.substring(3).trim().split("\\s+",3);if(parts.length==3){List<String[]>r=readRows("events",3);r.add(new String[]{UUID.randomUUID().toString(),parts[0]+" "+parts[1],parts[2]});writeRows("events",r);answer="予定を追加しました。";}else answer="形式: 予定 YYYY-MM-DD HH:mm 予定名";}else if(raw.startsWith("計算:")||raw.startsWith("計算：")){try{answer=Double.toString(new ExpressionParser(raw.substring(3)).parse());}catch(Exception e){answer="計算式を解析できません: "+e.getMessage();}}else if(raw.startsWith("翻訳:")||raw.startsWith("翻訳：")){String text=raw.substring(3).trim();openSafeUrl("https://translate.google.com/?sl=auto&tl=ja&text="+URLEncoder.encode(text,StandardCharsets.UTF_8));answer="Google翻訳を開きました。テキストはリンクに含まれます。";}else if(low.contains("todo")){List<String[]>r=readRows("todo."+LocalDate.now(),3);answer=r.isEmpty()?"今日のTodoはありません。":"今日のTodo:\n"+String.join("\n",r.stream().map(x->(Boolean.parseBoolean(x[2])?"☑ ":"□ ")+x[1]).toList());}else if(raw.contains("天気")){openProductivityTab("天気");loadWeather(true);answer="天気を更新しています。";}else if(raw.contains("予定")){List<String[]>r=readRows("events",3);answer=r.isEmpty()?"予定はありません。":"予定:\n"+String.join("\n",r.stream().map(x->x[1]+" "+x[2]).toList());}else if(raw.contains("文字化け")){openGarbler();answer="文字化けラボを開きました。";}else{answer="ローカル操作として認識できませんでした。メモ: / Todo: / 予定 YYYY-MM-DD HH:mm / 計算: を使えます。幅広い質問はChatGPT・Geminiへ手動で引き継げます。";}
        conversation.append("\nあなた: "+raw+"\nNEXUS: "+answer+"\n");conversation.setCaretPosition(conversation.getDocument().getLength());}

    private void openGames(){
        JDialog d=new JDialog(this,"NEXUS ミニゲーム",true);d.setSize(650,500);d.setLocationRelativeTo(this);JTabbedPane tabs=new JTabbedPane();
        JPanel drive=new JPanel(new BorderLayout());drive.add(new JLabel("🚗 ドライブゲーム：スタート後、左右キーで車を操作。障害物に当たらず進もう。",SwingConstants.CENTER),BorderLayout.NORTH);GamePanel gp=new GamePanel();drive.add(gp,BorderLayout.CENTER);drive.add(button("スタート",e->gp.start()),BorderLayout.SOUTH);
        JPanel snake=new JPanel(new BorderLayout());snake.add(new JLabel("🐍 スネーク：矢印キーで移動し、赤い餌を集めよう。壁や自分にぶつかると終了。",SwingConstants.CENTER),BorderLayout.NORTH);SnakePanel sp=new SnakePanel();snake.add(sp,BorderLayout.CENTER);snake.add(button("スタート / リスタート",e->sp.start()),BorderLayout.SOUTH);
        JPanel target=new JPanel(new BorderLayout());target.add(new JLabel("🎯 ターゲット練習：パネルをクリックして反射神経を試そう。",SwingConstants.CENTER),BorderLayout.NORTH);JButton targetBtn=button("🎯 HIT",e->{targetBtnFlash((JButton)e.getSource());});target.add(targetBtn,BorderLayout.CENTER);
        tabs.addTab("🚗 ドライブ",drive);tabs.addTab("🐍 スネーク",snake);tabs.addTab("🎯 ターゲット",target);d.add(tabs);d.setVisible(true);
    }
    private class SnakePanel extends JPanel {
        private static final int CELL=20, COLS=26, ROWS=17;
        private final LinkedList<Point> body=new LinkedList<>();
        private final Random random=new Random();
        private javax.swing.Timer timer;
        private int dx=1,dy=0,score=0;
        private Point food=new Point(15,8);
        private boolean running=false,gameOver=false;
        SnakePanel(){setBackground(new Color(5,15,32));setPreferredSize(new Dimension(COLS*CELL,ROWS*CELL));setFocusable(true);setDoubleBuffered(true);
            InputMap im=getInputMap(WHEN_IN_FOCUSED_WINDOW);ActionMap am=getActionMap();
            bindDirection(im,am,"LEFT",-1,0);bindDirection(im,am,"RIGHT",1,0);bindDirection(im,am,"UP",0,-1);bindDirection(im,am,"DOWN",0,1);
        }
        private void bindDirection(InputMap im,ActionMap am,String key,int ndx,int ndy){im.put(KeyStroke.getKeyStroke(key),key);am.put(key,new AbstractAction(){public void actionPerformed(ActionEvent e){if(!running)return;if(!(dx==-ndx&&dy==-ndy)){dx=ndx;dy=ndy;}}});}
        void start(){if(timer!=null)timer.stop();body.clear();body.add(new Point(7,8));body.add(new Point(6,8));body.add(new Point(5,8));dx=1;dy=0;score=0;gameOver=false;running=true;placeFood();timer=new javax.swing.Timer(125,e->step());timer.start();requestFocusInWindow();repaint();}
        private void placeFood(){for(int attempt=0;attempt<500;attempt++){Point p=new Point(random.nextInt(COLS),random.nextInt(ROWS));if(!body.contains(p)){food=p;return;}}}
        private void step(){if(!running)return;Point head=body.getFirst();Point next=new Point(head.x+dx,head.y+dy);if(next.x<0||next.x>=COLS||next.y<0||next.y>=ROWS||body.contains(next)){running=false;gameOver=true;timer.stop();Toolkit.getDefaultToolkit().beep();repaint();return;}body.addFirst(next);if(next.equals(food)){score+=10;placeFood();}else body.removeLast();repaint();}
        @Override protected void paintComponent(Graphics g){super.paintComponent(g);Graphics2D x=(Graphics2D)g.create();x.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);x.setColor(new Color(80,150,210,35));for(int c=0;c<=COLS;c++)x.drawLine(c*CELL,0,c*CELL,ROWS*CELL);for(int r=0;r<=ROWS;r++)x.drawLine(0,r*CELL,COLS*CELL,r*CELL);x.setColor(new Color(255,75,105));x.fillOval(food.x*CELL+3,food.y*CELL+3,CELL-6,CELL-6);for(int i=0;i<body.size();i++){Point q=body.get(i);x.setColor(i==0?new Color(95,245,210):new Color(38,175,170));x.fillRoundRect(q.x*CELL+2,q.y*CELL+2,CELL-4,CELL-4,7,7);}x.setColor(Color.WHITE);x.drawString("SCORE  "+score,10,15);if(!running){String msg=gameOver?"GAME OVER — スタート / リスタートで再挑戦":"スタートを押して開始";FontMetrics fm=x.getFontMetrics();x.setColor(new Color(2,8,20,205));x.fillRoundRect(45,getHeight()/2-27,getWidth()-90,54,14,14);x.setColor(Color.WHITE);x.drawString(msg,(getWidth()-fm.stringWidth(msg))/2,getHeight()/2+5);}x.dispose();}
    }
    private void targetBtnFlash(JButton b){b.setText("✨ NICE!");new javax.swing.Timer(500,e->{b.setText("🎯 HIT");((javax.swing.Timer)e.getSource()).stop();}).start();}
    private class GamePanel extends JPanel{int x=170,obstacle=0;boolean running;javax.swing.Timer t;GamePanel(){setBackground(new Color(6,16,35));setFocusable(true);addKeyListener(new KeyAdapter(){public void keyPressed(KeyEvent e){if(e.getKeyCode()==KeyEvent.VK_LEFT)x=Math.max(30,x-18);if(e.getKeyCode()==KeyEvent.VK_RIGHT)x=Math.min(300,x+18);repaint();}});}void start(){running=true;if(t!=null)t.stop();t=new javax.swing.Timer(40,e->{obstacle=(obstacle+7)%getHeight();if(Math.abs(x-170)<26&&Math.abs(obstacle-getHeight()/2)<24){running=false;((javax.swing.Timer)e.getSource()).stop();}repaint();});t.start();requestFocusInWindow();}protected void paintComponent(Graphics g){super.paintComponent(g);g.setColor(Color.WHITE);g.drawLine(getWidth()/2,0,getWidth()/2,getHeight());g.setColor(Color.RED);g.fillRoundRect(x,getHeight()-70,38,60,10,10);g.setColor(Color.ORANGE);g.fillOval(getWidth()/2-10,obstacle,20,20);g.setColor(TEXT);g.drawString(running?"運転中 — ← → キー":"スタートを押して開始",10,18);}}

    private JDialog busyDialog(String title,String message){JDialog d=new JDialog(this,title,false);JPanel p=new JPanel(new BorderLayout(8,8));p.setBorder(new EmptyBorder(20,20,20,20));p.add(new JLabel(message),BorderLayout.CENTER);JProgressBar bar=new JProgressBar();bar.setIndeterminate(true);p.add(bar,BorderLayout.SOUTH);d.setContentPane(p);d.pack();d.setLocationRelativeTo(this);d.setDefaultCloseOperation(WindowConstants.DO_NOTHING_ON_CLOSE);return d;}
    private void copy(String s){if(s==null||s.isEmpty()){showInfo("コピーする内容がありません。");return;}Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new java.awt.datatransfer.StringSelection(s),null);showInfo("クリップボードにコピーしました。");}
    private void saveTextFile(String name,String text){JFileChooser fc=new JFileChooser();fc.setSelectedFile(new File(name));if(fc.showSaveDialog(this)==JFileChooser.APPROVE_OPTION){try{Files.writeString(fc.getSelectedFile().toPath(),text,StandardCharsets.UTF_8);showInfo("保存しました: "+fc.getSelectedFile());}catch(Exception ex){showError("ファイル保存に失敗しました",ex);}}}
    private void clearOwnedData(){if(JOptionPane.showConfirmDialog(this,"NEXUSが使用するローカル保存データをすべて削除します。バックアップは先に作成してください。","保存データの削除",JOptionPane.YES_NO_OPTION,JOptionPane.WARNING_MESSAGE)!=JOptionPane.YES_OPTION)return;data.clear();saveData();showInfo("保存データを削除しました。アプリを再起動してください。");}
    private void showInfo(String s){JOptionPane.showMessageDialog(this,s,"NEXUS",JOptionPane.INFORMATION_MESSAGE);}
    private void showError(String s,Exception e){JOptionPane.showMessageDialog(this,s+"\n"+e.getMessage(),"NEXUS Error",JOptionPane.ERROR_MESSAGE);}
    private void shutdown(){if(countTimer!=null)countTimer.stop();if(stopwatchTimer!=null)stopwatchTimer.stop();if(clockTimer!=null)clockTimer.stop();stopAudio();workers.shutdownNow();dispose();System.exit(0);}

    private static final class TodoRenderer extends JCheckBox implements ListCellRenderer<String>{TodoRenderer(){setOpaque(true);setForeground(TEXT);setBackground(PANEL);}public Component getListCellRendererComponent(JList<? extends String>l,String v,int i,boolean s,boolean f){setText(v);setSelected(v.startsWith("☑"));setBackground(s?PANEL2:PANEL);return this;}}
    private class NebulaPanel extends JPanel{NebulaPanel(){setOpaque(true);}protected void paintComponent(Graphics g){super.paintComponent(g);Graphics2D x=(Graphics2D)g.create();x.setPaint(new GradientPaint(0,0,new Color(6,13,34),getWidth(),getHeight(),new Color(23,12,49)));x.fillRect(0,0,getWidth(),getHeight());for(int i=0;i<70;i++){int px=(i*97+31)%Math.max(1,getWidth()),py=(i*53+17)%Math.max(1,getHeight());x.setColor(new Color(120,205,255,(i%4+1)*25));x.fillOval(px,py,i%3+1,i%3+1);}x.dispose();}}
    private class ClockFace extends JPanel{ClockFace(){setOpaque(false);}protected void paintComponent(Graphics g){super.paintComponent(g);Graphics2D x=(Graphics2D)g.create();x.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);int s=Math.min(getWidth(),getHeight())-12,cx=getWidth()/2,cy=getHeight()/2,r=s/2;x.setColor(new Color(accent.getRed(),accent.getGreen(),accent.getBlue(),40));x.fillOval(cx-r,cy-r,2*r,2*r);x.setColor(accent);x.setStroke(new BasicStroke(2));x.drawOval(cx-r,cy-r,2*r,2*r);for(int i=0;i<12;i++){double a=i*Math.PI/6-Math.PI/2;int x1=(int)(cx+Math.cos(a)*(r-5)),y1=(int)(cy+Math.sin(a)*(r-5)),x2=(int)(cx+Math.cos(a)*(r-12)),y2=(int)(cy+Math.sin(a)*(r-12));x.drawLine(x1,y1,x2,y2);}LocalTime t=LocalTime.now();double[]ang={ (t.getHour()%12+t.getMinute()/60.0)*Math.PI/6,(t.getMinute()+t.getSecond()/60.0)*Math.PI/30,t.getSecond()*Math.PI/30};int[]len={r*.48>0?(int)(r*.48):0,(int)(r*.68),(int)(r*.78)};for(int i=0;i<3;i++){x.setStroke(new BasicStroke(i==2?1.3f:3f,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND));x.setColor(i==2?accent:TEXT);x.drawLine(cx,cy,(int)(cx+Math.sin(ang[i])*len[i]),(int)(cy-Math.cos(ang[i])*len[i]));}x.fillOval(cx-4,cy-4,8,8);x.dispose();}}

    public static void main(String[] args){SwingUtilities.invokeLater(()->new NexusSuper41().setVisible(true));}
}
