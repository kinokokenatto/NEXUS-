// NEXUS SUPER4.1 — Native C# edition
// Copyright notice and usage terms are reproduced from the supplied NEXUS SUPER4.1 HTML.
// This application is a native Windows Forms implementation; it does not host or execute the source HTML/JavaScript.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Data;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Media;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace NexusSuper41;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        ApplicationConfiguration.Initialize();
        Application.Run(new MainForm());
    }
}

#region Data models and persistence
public sealed class AppState
{
    public List<AppLink> Apps { get; set; } = DefaultApps();
    public List<MemoItem> Memos { get; set; } = new();
    public Dictionary<string, List<TodoItem>> Todos { get; set; } = new();
    public List<PlanItem> Events { get; set; } = new();
    public List<BoardItem> Board { get; set; } = new();
    public string WeatherPrefecture { get; set; } = "兵庫県";
    public bool AutoWeather { get; set; }
    public bool ScreenProtect { get; set; }
    public bool AnonCommunication { get; set; }
    public bool PrivacyShield { get; set; }
    public string Accent { get; set; } = "#39D8FF";
    public bool FastMode { get; set; }
    public bool ReducedMotion { get; set; }
    public string SleepStart { get; set; } = "22:00";
    public string SleepEnd { get; set; } = "07:00";
    public bool SleepEnabled { get; set; }
    public string? DrawingPng { get; set; }
    public string DrawBackground { get; set; } = "#FFFFFF";
    public string? WallpaperFile { get; set; }
    public int PlanetCoins { get; set; }

    private static List<AppLink> DefaultApps() => new()
    {
        new("Google", "https://www.google.com/"), new("YouTube", "https://www.youtube.com/"),
        new("Gmail", "https://mail.google.com/"), new("Google Drive", "https://drive.google.com/"),
        new("Google Calendar", "https://calendar.google.com/"), new("Google Maps", "https://maps.google.com/"),
        new("ChatGPT", "https://chatgpt.com/"), new("Gemini", "https://gemini.google.com/app"),
        new("Claude", "https://claude.ai/new"), new("Wikipedia", "https://ja.wikipedia.org/")
    };
}

public sealed record AppLink(string Name, string Url);
public sealed class MemoItem { public string Id { get; set; } = Guid.NewGuid().ToString("N"); public string Title { get; set; } = ""; public string Body { get; set; } = ""; public bool Pinned { get; set; } public DateTime Updated { get; set; } = DateTime.Now; }
public sealed class TodoItem { public string Text { get; set; } = ""; public bool Done { get; set; } public DateTime Created { get; set; } = DateTime.Now; }
public sealed class PlanItem { public string Id { get; set; } = Guid.NewGuid().ToString("N"); public DateTime Start { get; set; } public string Title { get; set; } = ""; }
public sealed class BoardItem { public string Id { get; set; } = Guid.NewGuid().ToString("N"); public string Type { get; set; } = "主の最近の感想"; public string Title { get; set; } = ""; public string Body { get; set; } = ""; public DateTime Created { get; set; } = DateTime.Now; public DateTime Updated { get; set; } = DateTime.Now; }

internal static class Store
{
    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true, PropertyNameCaseInsensitive = true };
    public static readonly string Root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "NEXUS SUPER4.1");
    public static readonly string StatePath = Path.Combine(Root, "state.json");
    public static AppState Load()
    {
        try
        {
            Directory.CreateDirectory(Root);
            if (File.Exists(StatePath)) return JsonSerializer.Deserialize<AppState>(File.ReadAllText(StatePath, Encoding.UTF8), Options) ?? new AppState();
        }
        catch { }
        return new AppState();
    }
    public static void Save(AppState state)
    {
        Directory.CreateDirectory(Root);
        string temp = StatePath + ".tmp";
        File.WriteAllText(temp, JsonSerializer.Serialize(state, Options), new UTF8Encoding(false));
        File.Move(temp, StatePath, true);
    }
    public static string Serialize(AppState state) => JsonSerializer.Serialize(state, Options);
    public static AppState Deserialize(string json) => JsonSerializer.Deserialize<AppState>(json, Options) ?? throw new InvalidDataException("バックアップの内容を読み込めません。");
}
#endregion

#region Main application
public sealed class MainForm : Form
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(12) };
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };
    private AppState _state;
    private readonly TabControl _tabs = new();
    private readonly Label _clock = new();
    private readonly Label _date = new();
    private readonly Label _status = new();
    private readonly AnalogClockControl _analogClock = new();
    private readonly System.Windows.Forms.Timer _clockTimer = new() { Interval = 500 };
    private readonly System.Windows.Forms.Timer _weatherTimer = new() { Interval = 30 * 60 * 1000 };
    private ComboBox? _weatherPrefectureControl;
    private Label? _weatherResultControl;
    private Label? _weatherStatusControl;
    private readonly System.Windows.Forms.Timer _sleepTimer = new() { Interval = 15000 };
    private readonly Stopwatch _stopwatch = new();
    private readonly System.Windows.Forms.Timer _watchTimer = new() { Interval = 50 };
    private double _countdownSeconds;
    private DateTime _countdownEnds;
    private bool _countdownRunning;
    private readonly Label _countdownDisplay = new();
    private readonly Label _stopwatchDisplay = new();
    private readonly ListBox _memoList = new();
    private readonly TextBox _memoTitle = new();
    private readonly TextBox _memoBody = new();
    private readonly ListBox _todoList = new();
    private readonly DateTimePicker _todoDate = new() { Format = DateTimePickerFormat.Short };
    private readonly ListBox _eventList = new();
    private readonly ListBox _boardList = new();
    private readonly TextBox _boardTitle = new();
    private readonly TextBox _boardBody = new();
    private readonly DrawingSurface _drawing = new();
    private MiniGameSurface? _game;
    private string? _selectedMemoId;
    private string? _selectedBoardId;
    private string _currentTodoDate = DateTime.Today.ToString("yyyy-MM-dd");
    private SoundPlayer? _player;
    private string? _tempTonePath;
    private bool _devEnabled;
    private bool _adminEnabled;
    private Form? _sleepOverlay;
    private DateTime _sleepBypassUntil;
    private int _errorCount;
    private readonly Dictionary<string, (double Lat, double Lon, string Note)> _prefectures = new();

    private readonly Color Bg = Color.FromArgb(3, 7, 19);
    private Color Accent => ColorTranslator.FromHtml(IsColor(_state.Accent) ? _state.Accent : "#39D8FF");
    private static bool IsColor(string s) => Regex.IsMatch(s ?? "", "^#[0-9a-fA-F]{6}$");

    public MainForm()
    {
        _state = Store.Load();
        BuildPrefectures();
        Text = "NEXUS SUPER4.1 — C# Native Edition";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(980, 700);
        Size = new Size(1420, 940);
        BackColor = Bg;
        ForeColor = Color.FromArgb(235, 245, 255);
        Font = new Font("Yu Gothic UI", 9.5f);
        DoubleBuffered = true;
        KeyPreview = true;
        BuildInterface();
        try
        {
            string? savedWallpaper = _state.WallpaperFile;
            string wp = !string.IsNullOrWhiteSpace(savedWallpaper) && File.Exists(savedWallpaper)
                ? savedWallpaper : Path.Combine(AppContext.BaseDirectory, "assets", "nexus-wallpaper.jpg");
            if (File.Exists(wp)) _wallpaper = new Bitmap(wp);
        }
        catch { }
        KeyDown += (_, e) => _game?.HandleKey(e.KeyCode);
        _weatherTimer.Tick += async (_, _) =>
        {
            if (_state.AutoWeather && !_state.AnonCommunication && _weatherPrefectureControl != null && _weatherResultControl != null && _weatherStatusControl != null)
                await LoadWeatherAsync(_weatherPrefectureControl, _weatherResultControl, _weatherStatusControl);
        };
        if (_state.AutoWeather && !_state.AnonCommunication) Shown += async (_, _) =>
        {
            if (_weatherPrefectureControl != null && _weatherResultControl != null && _weatherStatusControl != null)
                await LoadWeatherAsync(_weatherPrefectureControl, _weatherResultControl, _weatherStatusControl);
            _weatherTimer.Start();
        };
        try { if (!string.IsNullOrWhiteSpace(_state.DrawingPng)) { using var ms = new MemoryStream(Convert.FromBase64String(_state.DrawingPng)); using var bmp = new Bitmap(ms); _drawing.LoadImage(new Bitmap(bmp)); } } catch { }
        _clockTimer.Tick += (_, _) => UpdateClock();
        _clockTimer.Start(); UpdateClock();
        _watchTimer.Tick += (_, _) => UpdateTimers(); _watchTimer.Start();
        _sleepTimer.Tick += (_, _) => CheckSleepRestriction(); _sleepTimer.Start();
        FormClosing += (_, _) => { _weatherTimer.Stop(); SaveDrawing(); SaveState(); _player?.Stop(); _player?.Dispose(); if (_tempTonePath != null) TryDelete(_tempTonePath); _wallpaper?.Dispose(); };
        ApplyTheme();
        CheckSleepRestriction();
    }

    private void BuildPrefectures()
    {
        // Representative administrative-center coordinates, matching the source app's prefecture selector.
        string[] rows = {
            "北海道|43.0642|141.3469|札幌市付近", "青森県|40.8244|140.7400|青森市付近", "岩手県|39.7036|141.1527|盛岡市付近", "宮城県|38.2682|140.8694|仙台市付近", "秋田県|39.7186|140.1024|秋田市付近", "山形県|38.2404|140.3633|山形市付近", "福島県|37.7503|140.4676|福島市付近", "茨城県|36.3418|140.4468|水戸市付近", "栃木県|36.5657|139.8836|宇都宮市付近", "群馬県|36.3907|139.0604|前橋市付近", "埼玉県|35.8617|139.6455|さいたま市付近", "千葉県|35.6073|140.1063|千葉市付近", "東京都|35.6895|139.6917|新宿区付近", "神奈川県|35.4478|139.6425|横浜市付近", "新潟県|37.9026|139.0236|新潟市付近", "富山県|36.6953|137.2113|富山市付近", "石川県|36.5944|136.6256|金沢市付近", "福井県|36.0652|136.2216|福井市付近", "山梨県|35.6642|138.5684|甲府市付近", "長野県|36.6513|138.1810|長野市付近", "岐阜県|35.3912|136.7223|岐阜市付近", "静岡県|34.9769|138.3831|静岡市付近", "愛知県|35.1802|136.9066|名古屋市付近", "三重県|34.7303|136.5086|津市付近", "滋賀県|35.0179|135.8546|大津市付近", "京都府|35.0116|135.7681|京都市付近", "大阪府|34.6863|135.5200|大阪市付近", "兵庫県|34.6913|135.1830|神戸市付近", "奈良県|34.6851|135.8329|奈良市付近", "和歌山県|34.2260|135.1675|和歌山市付近", "鳥取県|35.5039|134.2377|鳥取市付近", "島根県|35.4723|133.0505|松江市付近", "岡山県|34.6618|133.9344|岡山市付近", "広島県|34.3963|132.4596|広島市付近", "山口県|34.1861|131.4705|山口市付近", "徳島県|34.0658|134.5593|徳島市付近", "香川県|34.3401|134.0434|高松市付近", "愛媛県|33.8416|132.7657|松山市付近", "高知県|33.5597|133.5311|高知市付近", "福岡県|33.6064|130.4183|福岡市付近", "佐賀県|33.2494|130.2988|佐賀市付近", "長崎県|32.7448|129.8737|長崎市付近", "熊本県|32.7898|130.7417|熊本市付近", "大分県|33.2382|131.6126|大分市付近", "宮崎県|31.9111|131.4239|宮崎市付近", "鹿児島県|31.5602|130.5581|鹿児島市付近", "沖縄県|26.2124|127.6809|那覇市付近"
        };
        foreach (string row in rows) { var p = row.Split('|'); _prefectures[p[0]] = (double.Parse(p[1]), double.Parse(p[2]), p[3]); }
    }

    private void BuildInterface()
    {
        var root = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 3, ColumnCount = 1, Padding = new Padding(14), BackColor = Color.Transparent };
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 48));
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 130));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        Controls.Add(root);
        var header = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.LeftToRight, WrapContents = false, AutoScroll = true, BackColor = Color.Transparent };
        var logo = new Label { Text = "◈ NEXUS SUPER4.1", Font = new Font("Yu Gothic UI", 17, FontStyle.Bold), ForeColor = Accent, AutoSize = true, Padding = new Padding(0, 4, 22, 0) };
        header.Controls.Add(logo);
        AddHeaderButton(header, "⌘ ランチャー", () => OpenCommandPalette());
        AddHeaderButton(header, "📝 掲示板", () => _tabs.SelectedIndex = 2);
        AddHeaderButton(header, "💻 CodeBridge", () => _tabs.SelectedIndex = 5);
        AddHeaderButton(header, "🔎 URL検査", () => _tabs.SelectedIndex = 6);
        AddHeaderButton(header, "⚙ 設定", () => _tabs.SelectedIndex = 7);
        AddHeaderButton(header, "⚠ 開発者", () => OpenDeveloper());
        AddHeaderButton(header, "🔒 画面保護", () => ShowPrivacyOverlay());
        _status.Text = "準備完了・端末内保存"; _status.ForeColor = Color.FromArgb(160, 220, 245); _status.AutoSize = true; _status.Margin = new Padding(14, 10, 4, 0);
        header.Controls.Add(_status);
        root.Controls.Add(header, 0, 0);

        var hero = new Panel { Dock = DockStyle.Fill, BackColor = Color.Transparent };
        _analogClock.SetBounds(22, 5, 108, 108); _analogClock.Accent = Accent; hero.Controls.Add(_analogClock);
        _clock.SetBounds(0, 0, 700, 82); _clock.Anchor = AnchorStyles.Top; _clock.Font = new Font("Segoe UI Light", 52, FontStyle.Regular); _clock.ForeColor = Accent; _clock.TextAlign = ContentAlignment.MiddleCenter;
        _date.SetBounds(0, 78, 700, 28); _date.Anchor = AnchorStyles.Top; _date.Font = new Font("Yu Gothic UI", 12); _date.ForeColor = Color.FromArgb(167, 227, 255); _date.TextAlign = ContentAlignment.MiddleCenter;
        hero.Controls.Add(_clock); hero.Controls.Add(_date);
        hero.Resize += (_, _) => { _clock.Left = (hero.ClientSize.Width - _clock.Width) / 2; _date.Left = (hero.ClientSize.Width - _date.Width) / 2; _analogClock.Left = 22; _analogClock.Top = Math.Max(0, (hero.ClientSize.Height - _analogClock.Height) / 2); };
        root.Controls.Add(hero, 0, 1);

        _tabs.Dock = DockStyle.Fill; _tabs.Padding = new Point(14, 6); _tabs.DrawMode = TabDrawMode.Normal;
        root.Controls.Add(_tabs, 0, 2);
        AddTab("ホーム", BuildHomePage());
        AddTab("整理・日常", BuildDailyPage());
        AddTab("掲示板", BuildBoardPage());
        AddTab("スタジオ", BuildStudioPage());
        AddTab("ゲーム", BuildGamesPage());
        AddTab("CodeBridge", BuildCodeBridgePage());
        AddTab("セキュリティ", BuildSecurityPage());
        AddTab("設定・バックアップ", BuildSettingsPage());
        AddTab("開発者・規約", BuildDeveloperPage());
    }

    private void AddTab(string name, Control content)
    {
        var page = new TabPage(name) { BackColor = Bg, ForeColor = ForeColor, Padding = new Padding(8) };
        page.Controls.Add(content); _tabs.TabPages.Add(page);
    }

    private FlowLayoutPanel PageFlow()
    {
        return new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(4), BackColor = Color.Transparent };
    }

    private Panel Card(string title, int height = 180)
    {
        var card = new Panel { Width = 1240, Height = height, BackColor = Color.FromArgb(224, 5, 15, 35), Margin = new Padding(4, 5, 4, 10), Padding = new Padding(14), BorderStyle = BorderStyle.FixedSingle };
        var heading = new Label { Text = title, ForeColor = Accent, Font = new Font("Yu Gothic UI", 11, FontStyle.Bold), AutoSize = true, Location = new Point(12, 8) };
        card.Controls.Add(heading);
        card.Resize += (_, _) => { foreach (Control c in card.Controls) if (c != heading) c.Width = Math.Max(150, card.ClientSize.Width - 30); };
        return card;
    }

    private void Place(Panel card, Control c, int x, int y, int width, int height)
    {
        c.Location = new Point(x, y); c.Size = new Size(width, height); card.Controls.Add(c);
    }

    private TextBox TextEntry(string placeholder = "", bool multiline = false)
    {
        var t = new TextBox { BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White, BorderStyle = BorderStyle.FixedSingle, Font = new Font("Yu Gothic UI", 9.5f), PlaceholderText = placeholder, Multiline = multiline, ScrollBars = multiline ? ScrollBars.Vertical : ScrollBars.None };
        return t;
    }

    private Button MakeButton(string text, Action click)
    {
        var b = new Button { Text = text, AutoSize = true, Height = 32, FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(22, 50, 84), ForeColor = Color.FromArgb(233, 246, 255), Margin = new Padding(3), Padding = new Padding(8, 2, 8, 2), Cursor = Cursors.Hand };
        b.FlatAppearance.BorderColor = Color.FromArgb(75, 165, 215); b.FlatAppearance.MouseOverBackColor = Color.FromArgb(36, 82, 125);
        b.Click += (_, _) => { try { click(); } catch (Exception ex) { _errorCount++; SetStatus("エラー: " + ex.Message); } };
        return b;
    }

    private void AddHeaderButton(FlowLayoutPanel panel, string text, Action click) => panel.Controls.Add(MakeButton(text, click));
    private void AddStatus(Panel card, int y = 0)
    {
        var lab = new Label { Text = "", ForeColor = Color.FromArgb(168, 218, 245), AutoSize = false, Height = 24, Width = 1160, Location = new Point(14, y) };
        card.Controls.Add(lab); card.Tag = lab;
    }
    private void SetCardStatus(Panel card, string message) { if (card.Tag is Label lab) lab.Text = message; }
    private void SetStatus(string message) { _status.Text = message; }
    private void SaveState() { try { Store.Save(_state); SetStatus("端末内に保存しました。"); } catch (Exception ex) { SetStatus("保存エラー: " + ex.Message); } }
    private void UpdateClock() { DateTime now = DateTime.Now; _clock.Text = now.ToString("HH:mm:ss"); _date.Text = now.ToString("yyyy年M月d日（dddd）", System.Globalization.CultureInfo.GetCultureInfo("ja-JP")); _analogClock.Invalidate(); }

    protected override void OnPaintBackground(PaintEventArgs e)
    {
        base.OnPaintBackground(e);
        using var brush = new LinearGradientBrush(ClientRectangle, Color.FromArgb(3, 5, 17), Color.FromArgb(14, 10, 43), 35f);
        e.Graphics.FillRectangle(brush, ClientRectangle);
        using var rnd = new SolidBrush(Color.FromArgb(105, 125, 203, 255));
        for (int i = 0; i < 110; i++) { int x = (i * 131 + 47) % Math.Max(1, ClientSize.Width); int y = (i * 79 + 11) % Math.Max(1, ClientSize.Height); int d = i % 9 == 0 ? 3 : 1; e.Graphics.FillEllipse(rnd, x, y, d, d); }
    }

    private Control BuildHomePage()
    {
        var flow = PageFlow();
        var search = Card("⌕ 検索・Webアクセス", 115);
        var query = TextEntry("検索キーワードまたはURLを入力。Enterで検索"); query.Font = new Font("Yu Gothic UI", 12); Place(search, query, 14, 42, 850, 38);
        Place(search, MakeButton("Google検索", () => SearchWeb(query.Text)), 875, 42, 120, 34);
        Place(search, MakeButton("Bing検索", () => OpenUrl("https://www.bing.com/search?q=" + Uri.EscapeDataString(query.Text))), 1000, 42, 120, 34);
        query.KeyDown += (_, e) => { if (e.KeyCode == Keys.Enter) { e.SuppressKeyPress = true; SearchWeb(query.Text); } };
        flow.Controls.Add(search);

        var apps = Card("🚀 アプリランチャー / ブックマーク", 255);
        var appList = new FlowLayoutPanel { Location = new Point(12, 38), Size = new Size(1180, 135), WrapContents = true, AutoScroll = true, BackColor = Color.Transparent };
        Place(apps, appList, 12, 38, 1180, 135); RenderApps(appList);
        var appName = TextEntry("アプリ名"); var appUrl = TextEntry("URL（例 https://example.com）");
        Place(apps, appName, 14, 184, 230, 32); Place(apps, appUrl, 252, 184, 650, 32);
        Place(apps, MakeButton("＋ 追加", () => { if (string.IsNullOrWhiteSpace(appName.Text) || !NormalizeUrl(appUrl.Text, out string u)) { MessageBox.Show("アプリ名と有効なURLを入力してください。"); return; } _state.Apps.Add(new AppLink(appName.Text.Trim(), u)); SaveState(); RenderApps(appList); appName.Clear(); appUrl.Clear(); }), 910, 184, 95, 32);
        Place(apps, MakeButton("アプリ一覧を更新", () => RenderApps(appList)), 1010, 184, 150, 32);
        flow.Controls.Add(apps);

        var news = Card("📰 今日のニュース / 配信元リンク", 155);
        string[,] links = { { "Google News", "https://news.google.com/" }, { "NHK NEWS", "https://www3.nhk.or.jp/news/" }, { "Yahoo!ニュース", "https://news.yahoo.co.jp/" }, { "BBC News Japan", "https://www.bbc.com/japanese" }, { "神戸新聞", "https://www.kobe-np.co.jp/" }, { "ITmedia", "https://www.itmedia.co.jp/" } };
        int nx = 14; for (int i = 0; i < links.GetLength(0); i++) { string label = links[i, 0], url = links[i, 1]; Place(news, MakeButton(label, () => OpenUrl(url)), nx, 48, 145, 34); nx += 153; if (nx > 1000) nx = 14; }
        flow.Controls.Add(news);

        var update = Card("🆕 NEXUS SUPER4.1 更新情報", 165);
        Place(update, new Label { Text = "機能整理・開発者権限拡張版\n背景のちらつきを抑え、診断・データ管理・おやすみ制限を強化。天気は全国47都道府県の代表地点に対応。", ForeColor = Color.Gainsboro, AutoSize = false }, 14, 42, 1160, 60);
        Place(update, MakeButton("更新履歴を見る", () => MessageBox.Show("2026-10-30 NEXUS 3.3.6 おやすみ制限・開発者モード・静かな背景\n2026-10-30 NEXUS 3.3.5 掲示板記録\n2026-10-30 3.3.4 ネットワーク速度測定\n2026-10-30 3.3.3 地域別天気・24時間降水量\n2026-10-27 3.3.0 CodeBridge・統合ランチャー・システムモニター", "NEXUS更新ニュース")), 14, 112, 170, 32);
        flow.Controls.Add(update);

        var system = Card("◈ NEXUS SYSTEM MONITOR（端末内のみ）", 135);
        var monitor = new Label { Text = GetSystemMetrics(), ForeColor = Color.FromArgb(193, 224, 244), AutoSize = false };
        Place(system, monitor, 14, 42, 990, 58);
        Place(system, MakeButton("↻ 状態を更新", () => monitor.Text = GetSystemMetrics()), 1015, 48, 150, 34);
        flow.Controls.Add(system);
        return flow;
    }

    private void RenderApps(FlowLayoutPanel panel)
    {
        panel.Controls.Clear();
        for (int i = 0; i < _state.Apps.Count; i++)
        {
            var item = _state.Apps[i]; int ix = i;
            var b = new Button { Text = "◈\n" + item.Name + "\n開く", Width = 132, Height = 77, FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(18, 38, 75), ForeColor = Color.White, Margin = new Padding(5), TextAlign = ContentAlignment.MiddleCenter };
            b.FlatAppearance.BorderColor = Accent; b.Click += (_, _) => OpenUrl(item.Url);
            b.ContextMenuStrip = new ContextMenuStrip(); b.ContextMenuStrip.Items.Add("URLをコピー", null, (_, _) => Clipboard.SetText(item.Url)); b.ContextMenuStrip.Items.Add("このアプリを削除", null, (_, _) => { if (MessageBox.Show("「" + item.Name + "」を削除しますか？", "確認", MessageBoxButtons.YesNo) == DialogResult.Yes) { _state.Apps.RemoveAt(ix); SaveState(); RenderApps(panel); } });
            panel.Controls.Add(b);
        }
    }

    private Control BuildDailyPage()
    {
        var flow = PageFlow();
        BuildWeather(flow);
        BuildTimers(flow);
        BuildTodos(flow);
        BuildMemos(flow);
        BuildSchedule(flow);
        BuildTranslation(flow);
        BuildAudio(flow);
        BuildAssistantCard(flow);
        BuildNetworkAndCalculator(flow);
        return flow;
    }

    private void BuildWeather(FlowLayoutPanel flow)
    {
        var card = Card("🌤 天気 — 都道府県の代表地点", 235);
        var prefecture = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 220, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        prefecture.Items.AddRange(_prefectures.Keys.ToArray()); prefecture.SelectedItem = _prefectures.ContainsKey(_state.WeatherPrefecture) ? _state.WeatherPrefecture : "兵庫県";
        var result = new Label { Text = "⛅ -- °C\n「更新」を押すとOpen-Meteoから取得します。", ForeColor = Color.White, Font = new Font("Yu Gothic UI", 13), AutoSize = false };
        var status = new Label { Text = _state.AutoWeather ? "自動更新を許可しています（30分間隔）。" : "自動取得は初期設定で停止中です。", ForeColor = Color.LightSkyBlue, AutoSize = false };
        _weatherPrefectureControl = prefecture; _weatherResultControl = result; _weatherStatusControl = status;
        Place(card, prefecture, 14, 45, 220, 34);
        Place(card, MakeButton("🔄 更新", async () => await LoadWeatherAsync(prefecture, result, status)), 245, 45, 105, 34);
        Place(card, result, 14, 91, 1140, 70); Place(card, status, 14, 170, 1140, 34);
        prefecture.SelectedIndexChanged += (_, _) => { _state.WeatherPrefecture = prefecture.Text; SaveState(); result.Text = "地域を変更しました。必要なときに「更新」を押してください。"; };
        flow.Controls.Add(card);
    }

    private async Task LoadWeatherAsync(ComboBox prefecture, Label result, Label status)
    {
        if (_state.AnonCommunication) { result.Text = "通信匿名モードが有効なため、天気通信を停止しました。"; status.Text = "設定から通信匿名モードを解除すると取得できます。"; return; }
        string name = prefecture.Text; if (!_prefectures.TryGetValue(name, out var loc)) return;
        result.Text = "天気を取得中…"; status.Text = "Open-Meteoへ接続しています。";
        try
        {
            string url = $"https://api.open-meteo.com/v1/forecast?latitude={loc.Lat}&longitude={loc.Lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&wind_speed_unit=ms&timezone=Asia%2FTokyo&forecast_days=1";
            using var response = await Http.GetAsync(url); response.EnsureSuccessStatusCode(); using var stream = await response.Content.ReadAsStreamAsync(); using var json = await JsonDocument.ParseAsync(stream);
            var current = json.RootElement.GetProperty("current"); var daily = json.RootElement.GetProperty("daily");
            double temp = current.GetProperty("temperature_2m").GetDouble(); int code = current.GetProperty("weather_code").GetInt32(); int humidity = current.GetProperty("relative_humidity_2m").GetInt32();
            double feels = current.GetProperty("apparent_temperature").GetDouble(); double wind = current.GetProperty("wind_speed_10m").GetDouble(); double max = daily.GetProperty("temperature_2m_max")[0].GetDouble(); double min = daily.GetProperty("temperature_2m_min")[0].GetDouble(); int rain = daily.GetProperty("precipitation_probability_max")[0].GetInt32();
            string description = WeatherCode(code);
            result.Text = $"{WeatherEmoji(code)}  {name}（{loc.Note}）\n{temp:0.0}°C　{description}　体感 {feels:0}°C\n最高 {max:0}° / 最低 {min:0}°　降水確率 {rain}%　湿度 {humidity}%　風速 {wind:0.0} m/s";
            status.Text = "取得時刻 " + current.GetProperty("time").GetString() + "（JST） / Weather data by Open-Meteo";
        }
        catch (Exception ex) { status.Text = "取得できませんでした: " + ex.Message; result.Text = "⛅ 天気データを取得できませんでした。ネットワーク接続を確認してください。"; _errorCount++; }
    }

    private static string WeatherEmoji(int c) => c switch { 0 => "☀️", 1 => "🌤️", 2 => "⛅", 3 => "☁️", 45 or 48 => "🌫️", >= 51 and <= 67 => "🌧️", >= 71 and <= 77 => "🌨️", >= 80 and <= 86 => "🌦️", >= 95 => "⛈️", _ => "🌡️" };
    private static string WeatherCode(int c) => c switch { 0 => "快晴", 1 => "晴れ", 2 => "一部曇り", 3 => "曇り", 45 or 48 => "霧", 51 => "弱い霧雨", 53 => "霧雨", 55 => "強い霧雨", 61 => "小雨", 63 => "雨", 65 => "大雨", 71 => "小雪", 73 => "雪", 75 => "大雪", 80 => "にわか雨", 81 => "強いにわか雨", 82 => "激しいにわか雨", 95 => "雷雨", 96 or 99 => "雹を伴う雷雨", _ => "天気情報あり" };

    private void BuildTimers(FlowLayoutPanel flow)
    {
        var card = Card("⏱ タイマー / ストップウォッチ", 205);
        var minutes = new NumericUpDown { Minimum = 1, Maximum = 999, Value = 5, Width = 90, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        _countdownDisplay.Text = "05:00"; _countdownDisplay.Font = new Font("Segoe UI Light", 30); _countdownDisplay.ForeColor = Accent; _countdownDisplay.AutoSize = true;
        _stopwatchDisplay.Text = "00:00.00"; _stopwatchDisplay.Font = new Font("Segoe UI Light", 25); _stopwatchDisplay.ForeColor = Accent; _stopwatchDisplay.AutoSize = true;
        Place(card, new Label { Text = "タイマー（分）", AutoSize = true, ForeColor = Color.Gainsboro }, 14, 45, 130, 25); Place(card, minutes, 145, 41, 90, 30);
        Place(card, MakeButton("▶ 開始", () => { _countdownSeconds = (double)minutes.Value * 60; _countdownEnds = DateTime.Now.AddSeconds(_countdownSeconds); _countdownRunning = true; }), 245, 40, 90, 32);
        Place(card, MakeButton("停止", () => _countdownRunning = false), 340, 40, 70, 32); Place(card, MakeButton("リセット", () => { _countdownRunning = false; _countdownSeconds = (double)minutes.Value * 60; UpdateTimers(); }), 415, 40, 90, 32);
        Place(card, _countdownDisplay, 520, 35, 220, 52);
        Place(card, MakeButton("▶ ストップウォッチ", () => _stopwatch.Start()), 14, 115, 175, 32); Place(card, MakeButton("一時停止", () => _stopwatch.Stop()), 195, 115, 95, 32); Place(card, MakeButton("ラップ / リセット", () => { _stopwatch.Reset(); _stopwatch.Stop(); UpdateTimers(); }), 295, 115, 120, 32); Place(card, _stopwatchDisplay, 440, 105, 260, 55);
        flow.Controls.Add(card);
    }

    private void UpdateTimers()
    {
        if (_countdownRunning)
        {
            _countdownSeconds = Math.Max(0, (_countdownEnds - DateTime.Now).TotalSeconds);
            if (_countdownSeconds <= 0) { _countdownRunning = false; SystemSounds.Exclamation.Play(); SetStatus("タイマーが終了しました。"); }
        }
        int sec = (int)Math.Ceiling(_countdownSeconds); _countdownDisplay.Text = $"{sec / 60:00}:{sec % 60:00}";
        TimeSpan t = _stopwatch.Elapsed; _stopwatchDisplay.Text = $"{(int)t.TotalMinutes:00}:{t.Seconds:00}.{t.Milliseconds / 10:00}";
    }

    private void BuildTodos(FlowLayoutPanel flow)
    {
        var card = Card("✅ 日々のTodo", 290);
        var add = TextEntry("今日やることを追加…");
        Place(card, _todoDate, 14, 42, 145, 32); Place(card, add, 170, 42, 650, 32);
        Place(card, MakeButton("＋ 追加", () => { if (string.IsNullOrWhiteSpace(add.Text)) return; var list = GetTodos(); if (list.Count >= 200) { MessageBox.Show("1日あたり最大200件です。"); return; } list.Add(new TodoItem { Text = add.Text.Trim() }); add.Clear(); SaveState(); RenderTodos(); }), 830, 42, 95, 32);
        Place(card, MakeButton("今日に戻る", () => { _todoDate.Value = DateTime.Today; _currentTodoDate = DateTime.Today.ToString("yyyy-MM-dd"); RenderTodos(); }), 930, 42, 105, 32);
        Place(card, MakeButton("完了分を削除", () => { GetTodos().RemoveAll(x => x.Done); SaveState(); RenderTodos(); }), 1040, 42, 125, 32);
        _todoList.SetBounds(14, 88, 1145, 175); _todoList.BackColor = Color.FromArgb(7, 13, 30); _todoList.ForeColor = Color.White; card.Controls.Add(_todoList);
        _todoDate.ValueChanged += (_, _) => { _currentTodoDate = _todoDate.Value.ToString("yyyy-MM-dd"); RenderTodos(); };
        _todoList.DoubleClick += (_, _) => { int ix = _todoList.SelectedIndex; var list = GetTodos(); if (ix >= 0 && ix < list.Count) { list[ix].Done = !list[ix].Done; SaveState(); RenderTodos(); } };
        var hint = new Label { Text = "項目をダブルクリックすると完了／未完了を切り替えます。", ForeColor = Color.LightSkyBlue, AutoSize = true, Location = new Point(14, 265) }; card.Controls.Add(hint);
        flow.Controls.Add(card); RenderTodos();
    }

    private List<TodoItem> GetTodos()
    {
        if (!_state.Todos.TryGetValue(_currentTodoDate, out var list)) _state.Todos[_currentTodoDate] = list = new List<TodoItem>();
        return list;
    }
    private void RenderTodos()
    {
        _todoList.BeginUpdate(); _todoList.Items.Clear(); foreach (var x in GetTodos()) _todoList.Items.Add((x.Done ? "☑ " : "□ ") + x.Text); _todoList.EndUpdate();
    }

    private void BuildMemos(FlowLayoutPanel flow)
    {
        var card = Card("📝 メモ管理", 340);
        _memoList.SetBounds(14, 45, 290, 245); _memoList.BackColor = Color.FromArgb(7, 13, 30); _memoList.ForeColor = Color.White; card.Controls.Add(_memoList);
        _memoTitle.PlaceholderText = "題名"; _memoTitle.SetBounds(320, 45, 840, 30); StyleInput(_memoTitle); card.Controls.Add(_memoTitle);
        _memoBody.Multiline = true; _memoBody.ScrollBars = ScrollBars.Vertical; _memoBody.PlaceholderText = "メモを入力…"; _memoBody.SetBounds(320, 82, 840, 177); StyleInput(_memoBody); card.Controls.Add(_memoBody);
        Place(card, MakeButton("＋ 新規", NewMemo), 320, 270, 90, 32); Place(card, MakeButton("💾 保存", SaveMemo), 415, 270, 90, 32); Place(card, MakeButton("📌 固定切替", ToggleMemoPin), 510, 270, 110, 32); Place(card, MakeButton("🗑 削除", DeleteMemo), 625, 270, 85, 32);
        Place(card, MakeButton("TXT保存", ExportMemos), 720, 270, 95, 32); Place(card, MakeButton("検索", () => RenderMemos()), 820, 270, 75, 32);
        _memoList.SelectedIndexChanged += (_, _) => LoadSelectedMemo();
        flow.Controls.Add(card); RenderMemos();
    }
    private void StyleInput(TextBox t) { t.BackColor = Color.FromArgb(7, 13, 30); t.ForeColor = Color.White; t.BorderStyle = BorderStyle.FixedSingle; }
    private void RenderMemos()
    {
        _memoList.Items.Clear(); foreach (var m in _state.Memos.OrderByDescending(x => x.Pinned).ThenByDescending(x => x.Updated)) _memoList.Items.Add(new MemoListItem(m));
    }
    private void LoadSelectedMemo() { if (_memoList.SelectedItem is MemoListItem li) { _selectedMemoId = li.Item.Id; _memoTitle.Text = li.Item.Title; _memoBody.Text = li.Item.Body; } }
    private void NewMemo() { _selectedMemoId = null; _memoTitle.Clear(); _memoBody.Clear(); _memoTitle.Focus(); }
    private void SaveMemo()
    {
        if (string.IsNullOrWhiteSpace(_memoTitle.Text) || string.IsNullOrWhiteSpace(_memoBody.Text)) { MessageBox.Show("題名と本文を入力してください。"); return; }
        var item = _state.Memos.FirstOrDefault(x => x.Id == _selectedMemoId);
        if (item == null) { item = new MemoItem(); _state.Memos.Add(item); _selectedMemoId = item.Id; }
        item.Title = _memoTitle.Text.Trim(); item.Body = _memoBody.Text; item.Updated = DateTime.Now; SaveState(); RenderMemos();
    }
    private void ToggleMemoPin() { var m = _state.Memos.FirstOrDefault(x => x.Id == _selectedMemoId); if (m == null) return; m.Pinned = !m.Pinned; m.Updated = DateTime.Now; SaveState(); RenderMemos(); }
    private void DeleteMemo() { var m = _state.Memos.FirstOrDefault(x => x.Id == _selectedMemoId); if (m == null) return; if (MessageBox.Show("このメモを削除しますか？", "確認", MessageBoxButtons.YesNo) != DialogResult.Yes) return; _state.Memos.Remove(m); NewMemo(); SaveState(); RenderMemos(); }
    private void ExportMemos() { using var d = new SaveFileDialog { Filter = "テキストファイル|*.txt", FileName = "NEXUS-memos.txt" }; if (d.ShowDialog() == DialogResult.OK) File.WriteAllText(d.FileName, string.Join("\r\n\r\n", _state.Memos.Select(m => $"# {m.Title}\r\n{m.Updated:g}\r\n{m.Body}")), Encoding.UTF8); }
    private sealed class MemoListItem { public MemoItem Item { get; } public MemoListItem(MemoItem item) => Item = item; public override string ToString() => (Item.Pinned ? "📌 " : "") + Item.Title + "  ·  " + Item.Updated.ToString("MM/dd HH:mm"); }

    private void BuildSchedule(FlowLayoutPanel flow)
    {
        var card = Card("📅 予定表", 265);
        var date = new DateTimePicker { Format = DateTimePickerFormat.Custom, CustomFormat = "yyyy年MM月dd日 HH:mm", Width = 220, Value = DateTime.Now.AddHours(1), CalendarForeColor = Color.White };
        var title = TextEntry("予定名");
        Place(card, date, 14, 45, 220, 32); Place(card, title, 245, 45, 520, 32);
        Place(card, MakeButton("＋ 予定を追加", () => { if (string.IsNullOrWhiteSpace(title.Text)) return; _state.Events.Add(new PlanItem { Start = date.Value, Title = title.Text.Trim() }); _state.Events = _state.Events.OrderBy(x => x.Start).ToList(); title.Clear(); SaveState(); RenderEvents(); }), 775, 45, 135, 32);
        _eventList.SetBounds(14, 88, 1145, 155); _eventList.BackColor = Color.FromArgb(7, 13, 30); _eventList.ForeColor = Color.White; card.Controls.Add(_eventList);
        _eventList.DoubleClick += (_, _) => { int i = _eventList.SelectedIndex; if (i < 0 || i >= _state.Events.Count) return; var ev = _state.Events.OrderBy(x => x.Start).ElementAt(i); if (MessageBox.Show("選択した予定を削除しますか？", "確認", MessageBoxButtons.YesNo) == DialogResult.Yes) { _state.Events.Remove(ev); SaveState(); RenderEvents(); } };
        card.Controls.Add(new Label { Text = "予定をダブルクリックすると削除できます。", ForeColor = Color.LightSkyBlue, AutoSize = true, Location = new Point(14, 242) });
        flow.Controls.Add(card); RenderEvents();
    }
    private void RenderEvents() { _eventList.Items.Clear(); foreach (var e in _state.Events.OrderBy(x => x.Start)) _eventList.Items.Add($"{e.Start:yyyy/MM/dd (ddd) HH:mm} 　{e.Title}"); }

    private void BuildTranslation(FlowLayoutPanel flow)
    {
        var card = Card("🌐 翻訳（外部サイトへ手動で引き継ぎ）", 260);
        var input = TextEntry("翻訳したい文章を入力…", true); input.SetBounds(14, 45, 540, 145); StyleInput(input); card.Controls.Add(input);
        var output = TextEntry("結果は翻訳サイト側で表示されます。", true); output.SetBounds(570, 45, 590, 145); StyleInput(output); output.ReadOnly = true; card.Controls.Add(output);
        Place(card, MakeButton("Google翻訳を開く", () => { if (string.IsNullOrWhiteSpace(input.Text)) return; if (MessageBox.Show("入力した文章をGoogle翻訳へ送信します。続けますか？", "外部送信の確認", MessageBoxButtons.YesNo) == DialogResult.Yes) OpenUrl("https://translate.google.com/?sl=auto&tl=en&text=" + Uri.EscapeDataString(input.Text)); }), 14, 200, 145, 32);
        Place(card, MakeButton("DeepLを開く", () => { if (string.IsNullOrWhiteSpace(input.Text)) return; if (MessageBox.Show("入力した文章をDeepLへ送信します。続けますか？", "外部送信の確認", MessageBoxButtons.YesNo) == DialogResult.Yes) OpenUrl("https://www.deepl.com/translator#ja/en/" + Uri.EscapeDataString(input.Text)); }), 165, 200, 120, 32);
        Place(card, MakeButton("入力を消去", () => input.Clear()), 290, 200, 95, 32);
        Place(card, new Label { Text = "このC#版ではブラウザー内蔵翻訳エンジンを利用できません。外部翻訳は確認後にサイトを開きます。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 405, 200, 740, 28);
        flow.Controls.Add(card);
    }

    private void BuildAudio(FlowLayoutPanel flow)
    {
        var card = Card("🎵 音楽・効果音", 125);
        Place(card, MakeButton("▶ 内蔵アンビエント音を再生", PlayAmbientTone), 14, 48, 230, 34);
        Place(card, MakeButton("■ 停止", () => { _player?.Stop(); }), 250, 48, 85, 34);
        Place(card, MakeButton("📂 WAVファイルを選ぶ", LoadWave), 345, 48, 170, 34);
        Place(card, new Label { Text = "ローカルWAV再生に対応。HTML版のWeb Audioによる複数トラック演奏機能は、Windows標準の簡易音源に置き換えています。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 530, 48, 640, 45);
        flow.Controls.Add(card);
    }

    private void PlayAmbientTone()
    {
        _player?.Stop(); _player?.Dispose();
        string path = Path.Combine(Store.Root, "ambient.wav"); Directory.CreateDirectory(Store.Root);
        WriteToneWav(path, 174.61, 5.0); _tempTonePath = path; _player = new SoundPlayer(path); _player.PlayLooping(); SetStatus("アンビエント音を再生中です。");
    }
    private static void WriteToneWav(string path, double hz, double seconds)
    {
        const int sampleRate = 22050; int count = (int)(sampleRate * seconds); using var fs = File.Create(path); using var bw = new BinaryWriter(fs);
        bw.Write(Encoding.ASCII.GetBytes("RIFF")); bw.Write(36 + count * 2); bw.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); bw.Write(16); bw.Write((short)1); bw.Write((short)1); bw.Write(sampleRate); bw.Write(sampleRate * 2); bw.Write((short)2); bw.Write((short)16); bw.Write(Encoding.ASCII.GetBytes("data")); bw.Write(count * 2);
        for (int i = 0; i < count; i++) { double env = Math.Min(1, Math.Min(i / 5000.0, (count - i) / 5000.0)); short sample = (short)(Math.Sin(2 * Math.PI * hz * i / sampleRate) * 5000 * Math.Max(0, env)); bw.Write(sample); }
    }
    private void LoadWave() { using var d = new OpenFileDialog { Filter = "WAV音声|*.wav" }; if (d.ShowDialog() != DialogResult.OK) return; _player?.Stop(); _player?.Dispose(); _player = new SoundPlayer(d.FileName); _player.Play(); }
#endregion

#region Bulletin board
    private Control BuildBoardPage()
    {
        var flow = PageFlow(); var card = Card("📝 NEXUS 掲示板記録", 515);
        var type = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 200, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        type.Items.AddRange(new object[] { "主の最近の感想", "近況・日記", "お知らせ", "アイデア・ひらめき", "その他" }); type.SelectedIndex = 0;
        Place(card, type, 14, 45, 200, 32); Place(card, _boardTitle, 225, 45, 930, 32); StyleInput(_boardTitle); _boardTitle.PlaceholderText = "タイトル";
        _boardBody.Multiline = true; _boardBody.ScrollBars = ScrollBars.Vertical; _boardBody.PlaceholderText = "本文"; _boardBody.SetBounds(225, 84, 930, 240); StyleInput(_boardBody); card.Controls.Add(_boardBody);
        Place(card, MakeButton("💾 記録を保存", () => SaveBoard(type.Text)), 225, 333, 130, 33);
        Place(card, MakeButton("＋ 新規", () => { _selectedBoardId = null; _boardTitle.Clear(); _boardBody.Clear(); }), 365, 333, 85, 33);
        Place(card, MakeButton("🗑 削除", DeleteBoard), 460, 333, 85, 33);
        Place(card, MakeButton("⬇ TXT保存", ExportBoard), 555, 333, 100, 33);
        _boardList.SetBounds(14, 45, 195, 360); _boardList.BackColor = Color.FromArgb(7, 13, 30); _boardList.ForeColor = Color.White; card.Controls.Add(_boardList);
        _boardList.SelectedIndexChanged += (_, _) => LoadBoard();
        Place(card, new Label { Text = "記録はこのPC内に保存されます。共有端末では他のユーザーに見られる可能性があります。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 225, 390, 900, 38);
        flow.Controls.Add(card); RenderBoard(); return flow;
    }
    private void RenderBoard() { _boardList.Items.Clear(); foreach (var b in _state.Board.OrderByDescending(x => x.Updated)) _boardList.Items.Add(new BoardListItem(b)); }
    private sealed class BoardListItem { public BoardItem Item { get; } public BoardListItem(BoardItem i) => Item = i; public override string ToString() => $"{Item.Type}｜{Item.Title} ({Item.Updated:MM/dd})"; }
    private void LoadBoard() { if (_boardList.SelectedItem is BoardListItem l) { _selectedBoardId = l.Item.Id; _boardTitle.Text = l.Item.Title; _boardBody.Text = l.Item.Body; } }
    private void SaveBoard(string type)
    {
        if (string.IsNullOrWhiteSpace(_boardTitle.Text) || string.IsNullOrWhiteSpace(_boardBody.Text)) { MessageBox.Show("タイトルと本文を入力してください。"); return; }
        if (_boardBody.Text.Length > 4000) { MessageBox.Show("本文は4,000文字以内です。"); return; }
        var b = _state.Board.FirstOrDefault(x => x.Id == _selectedBoardId);
        if (b == null) { b = new BoardItem(); _state.Board.Add(b); _selectedBoardId = b.Id; }
        b.Type = type; b.Title = _boardTitle.Text.Trim(); b.Body = _boardBody.Text; b.Updated = DateTime.Now; SaveState(); RenderBoard();
    }
    private void DeleteBoard() { var b = _state.Board.FirstOrDefault(x => x.Id == _selectedBoardId); if (b == null) return; if (MessageBox.Show("選択した記録を削除しますか？", "確認", MessageBoxButtons.YesNo) == DialogResult.Yes) { _state.Board.Remove(b); _selectedBoardId = null; _boardTitle.Clear(); _boardBody.Clear(); SaveState(); RenderBoard(); } }
    private void ExportBoard() { using var d = new SaveFileDialog { Filter = "テキスト|*.txt", FileName = "NEXUS-board.txt" }; if (d.ShowDialog() == DialogResult.OK) File.WriteAllText(d.FileName, string.Join("\r\n\r\n", _state.Board.Select(b => $"[{b.Type}] {b.Title}\r\n{b.Created:g}\r\n{b.Body}")), Encoding.UTF8); }
#endregion

#region Drawing and garbler
    private Control BuildStudioPage()
    {
        var flow = PageFlow(); var drawCard = Card("🎨 お絵かきスタジオ", 680);
        var color = new Button { Text = "色を選ぶ", Width = 95, Height = 30, BackColor = Color.White, ForeColor = Color.Black };
        color.Click += (_, _) => { using var d = new ColorDialog { Color = _drawing.DrawColor }; if (d.ShowDialog() == DialogResult.OK) { _drawing.DrawColor = d.Color; color.BackColor = d.Color; } };
        var size = new NumericUpDown { Minimum = 1, Maximum = 50, Value = 4, Width = 70, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        var brush = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 120, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; brush.Items.AddRange(new object[] { "ペン", "消しゴム", "直線", "四角形", "楕円" }); brush.SelectedIndex = 0;
        Place(drawCard, color, 14, 42, 95, 30); Place(drawCard, new Label { Text = "太さ", AutoSize = true, ForeColor = Color.Gainsboro }, 120, 48, 45, 22); Place(drawCard, size, 165, 42, 70, 30); Place(drawCard, brush, 245, 42, 120, 30);
        Place(drawCard, MakeButton("↩ 元に戻す", () => _drawing.Undo()), 375, 42, 105, 30); Place(drawCard, MakeButton("↪ やり直す", () => _drawing.Redo()), 485, 42, 95, 30); Place(drawCard, MakeButton("🗑 全消去", () => _drawing.Clear()), 585, 42, 90, 30); Place(drawCard, MakeButton("🖼 画像を開く", LoadDrawingImage), 680, 42, 115, 30); Place(drawCard, MakeButton("⬇ PNG保存", SaveDrawingAs), 800, 42, 100, 30);
        brush.SelectedIndexChanged += (_, _) => _drawing.Tool = brush.Text; size.ValueChanged += (_, _) => _drawing.PenWidth = (float)size.Value;
        _drawing.SetBounds(14, 86, 1180, 520); drawCard.Controls.Add(_drawing); flow.Controls.Add(drawCard);

        var garbleCard = Card("🧬 文字化けラボ", 310);
        var mode = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 220, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; mode.Items.AddRange(new object[] { "日本語・文字化け風", "カオス記号ノイズ", "UTF-8 Base64（復元可能）" }); mode.SelectedIndex = 0;
        var input = TextEntry("文字化けさせたい文章を入力…", true); input.SetBounds(14, 82, 550, 145); StyleInput(input); garbleCard.Controls.Add(input);
        var output = TextEntry("変換結果", true); output.SetBounds(580, 82, 580, 145); StyleInput(output); garbleCard.Controls.Add(output);
        Place(garbleCard, mode, 14, 42, 220, 30); Place(garbleCard, MakeButton("⚡ 変換", () => output.Text = Garble(input.Text, mode.Text)), 245, 42, 85, 30); Place(garbleCard, MakeButton("↩ 復元", () => { try { output.Text = Encoding.UTF8.GetString(Convert.FromBase64String(output.Text)); } catch { MessageBox.Show("Base64形式ではありません。"); } }), 335, 42, 85, 30); Place(garbleCard, MakeButton("出力→入力", () => input.Text = output.Text), 425, 42, 100, 30); Place(garbleCard, MakeButton("コピー", () => { if (!string.IsNullOrEmpty(output.Text)) Clipboard.SetText(output.Text); }), 530, 42, 80, 30); flow.Controls.Add(garbleCard);
        return flow;
    }
    private void LoadDrawingImage() { using var d = new OpenFileDialog { Filter = "画像ファイル|*.png;*.jpg;*.jpeg;*.bmp" }; if (d.ShowDialog() == DialogResult.OK) using (var image = Image.FromFile(d.FileName)) _drawing.LoadImage(new Bitmap(image)); }
    private void SaveDrawingAs() { using var d = new SaveFileDialog { Filter = "PNG画像|*.png", FileName = "NEXUS-drawing.png" }; if (d.ShowDialog() == DialogResult.OK) _drawing.Export(d.FileName); }
    private void SaveDrawing() { try { using var ms = new MemoryStream(); _drawing.Export(ms); _state.DrawingPng = Convert.ToBase64String(ms.ToArray()); _state.DrawBackground = ColorTranslator.ToHtml(_drawing.BackgroundColor); } catch { } }
    private static string Garble(string s, string mode)
    {
        if (mode.StartsWith("UTF-8")) return Convert.ToBase64String(Encoding.UTF8.GetBytes(s));
        if (mode.StartsWith("カオス")) { var rnd = new Random(); string chars = "※§※◇◆░▒▓█╳〆∴∞♢♧♤♨"; var b = new StringBuilder(); foreach (char c in s) b.Append(c).Append(chars[rnd.Next(chars.Length)]); return b.ToString(); }
        byte[] bytes = Encoding.UTF8.GetBytes(s); return Encoding.GetEncoding("shift_jis", EncoderFallback.ReplacementFallback, DecoderFallback.ReplacementFallback).GetString(bytes);
    }

    private sealed class DrawingSurface : Panel
    {
        private Bitmap _canvas = new(1200, 700);
        private readonly Stack<Bitmap> _undo = new(); private readonly Stack<Bitmap> _redo = new();
        private Point _last; private Point _start; private bool _drawing;
        public Color DrawColor { get; set; } = Color.Black; public Color BackgroundColor { get; private set; } = Color.White; public float PenWidth { get; set; } = 4; public string Tool { get; set; } = "ペン";
        public DrawingSurface()
        {
            DoubleBuffered = true; BackColor = Color.FromArgb(15, 24, 42); BorderStyle = BorderStyle.FixedSingle; _canvas = new Bitmap(1200, 700);
            using var g = Graphics.FromImage(_canvas); g.Clear(BackgroundColor);
            MouseDown += StartDraw; MouseMove += ContinueDraw; MouseUp += EndDraw;
        }
        protected override void OnPaint(PaintEventArgs e) { base.OnPaint(e); e.Graphics.InterpolationMode = InterpolationMode.HighQualityBicubic; e.Graphics.DrawImage(_canvas, ClientRectangle); }
        private Point ToCanvas(Point p) => new((int)(p.X * 1200.0 / Math.Max(1, ClientSize.Width)), (int)(p.Y * 700.0 / Math.Max(1, ClientSize.Height)));
        private void Snapshot() { if (_undo.Count >= 16) { var all = _undo.Reverse().Skip(1).ToList(); _undo.Clear(); foreach (var b in all) _undo.Push(b); } _undo.Push((Bitmap)_canvas.Clone()); foreach (var b in _redo) b.Dispose(); _redo.Clear(); }
        private void StartDraw(object? s, MouseEventArgs e) { if (e.Button != MouseButtons.Left) return; Snapshot(); _drawing = true; _last = _start = ToCanvas(e.Location); }
        private void ContinueDraw(object? s, MouseEventArgs e) { if (!_drawing) return; Point now = ToCanvas(e.Location); using var g = Graphics.FromImage(_canvas); g.SmoothingMode = SmoothingMode.AntiAlias; using var p = new Pen(Tool == "消しゴム" ? BackgroundColor : DrawColor, PenWidth) { StartCap = LineCap.Round, EndCap = LineCap.Round };
            if (Tool == "直線") { using var restore = new Bitmap(_undo.Peek()); g.DrawImage(restore, 0, 0); g.DrawLine(p, _start, now); } else if (Tool == "四角形") { using var restore = new Bitmap(_undo.Peek()); g.DrawImage(restore, 0, 0); g.DrawRectangle(p, Math.Min(_start.X, now.X), Math.Min(_start.Y, now.Y), Math.Abs(now.X - _start.X), Math.Abs(now.Y - _start.Y)); } else if (Tool == "楕円") { using var restore = new Bitmap(_undo.Peek()); g.DrawImage(restore, 0, 0); g.DrawEllipse(p, Math.Min(_start.X, now.X), Math.Min(_start.Y, now.Y), Math.Abs(now.X - _start.X), Math.Abs(now.Y - _start.Y)); } else g.DrawLine(p, _last, now);
            _last = now; Invalidate(); }
        private void EndDraw(object? s, MouseEventArgs e) { _drawing = false; }
        public void Undo() { if (_undo.Count == 0) return; _redo.Push((Bitmap)_canvas.Clone()); _canvas.Dispose(); _canvas = _undo.Pop(); Invalidate(); }
        public void Redo() { if (_redo.Count == 0) return; _undo.Push((Bitmap)_canvas.Clone()); _canvas.Dispose(); _canvas = _redo.Pop(); Invalidate(); }
        public void Clear() { Snapshot(); using var g = Graphics.FromImage(_canvas); g.Clear(BackgroundColor); Invalidate(); }
        public void LoadImage(Bitmap image) { Snapshot(); using var g = Graphics.FromImage(_canvas); g.DrawImage(image, new Rectangle(0, 0, 1200, 700)); image.Dispose(); Invalidate(); }
        public void Export(string path) => _canvas.Save(path, ImageFormat.Png);
        public void Export(Stream stream) => _canvas.Save(stream, ImageFormat.Png);
    }
#endregion

#region CodeBridge and language workshop
    private Control BuildCodeBridgePage()
    {
        var flow = PageFlow();
        var convert = Card("💻 NEXUS CodeBridge — 言語間コード変換", 610);
        string[] langs = { "Python", "JavaScript", "Java", "Go", "R", "TypeScript", "C", "C#", "C++", "Cython", "Rust", "PHP", "HTML", "BASIC", "SQL", "Elixir", "Haskell" };
        var src = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 180, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; src.Items.AddRange(langs); src.SelectedItem = "JavaScript";
        var dst = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 180, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; dst.Items.AddRange(langs); dst.SelectedItem = "C#";
        var codeIn = TextEntry("変換したいコードを入力…", true); codeIn.SetBounds(14, 94, 560, 205); StyleInput(codeIn); codeIn.Font = new Font("Consolas", 10);
        var codeOut = TextEntry("変換結果", true); codeOut.SetBounds(590, 94, 570, 205); StyleInput(codeOut); codeOut.Font = new Font("Consolas", 10); codeOut.ReadOnly = true;
        var conversionStatus = new Label { Text = "基本的な変数・出力・コメント構文を中心にローカル変換します。複雑な構文の完全互換を保証するものではありません。", ForeColor = Color.LightSkyBlue, AutoSize = false };
        Place(convert, new Label { Text = "変換元", AutoSize = true, ForeColor = Color.Gainsboro }, 14, 44, 70, 25); Place(convert, src, 86, 40, 180, 32);
        Place(convert, new Label { Text = "変換先", AutoSize = true, ForeColor = Color.Gainsboro }, 280, 44, 70, 25); Place(convert, dst, 350, 40, 180, 32);
        Place(convert, MakeButton("🧪 サンプル", () => codeIn.Text = SampleFor(src.Text)), 545, 40, 105, 32);
        Place(convert, MakeButton("⚡ 変換", () => { codeOut.Text = ConvertCode(codeIn.Text, src.Text, dst.Text); conversionStatus.Text = "変換処理を完了しました。必ず実行環境でコンパイル・テストしてください。"; }), 655, 40, 85, 32);
        Place(convert, MakeButton("⇄ 入替", () => { (src.SelectedItem, dst.SelectedItem) = (dst.SelectedItem, src.SelectedItem); }), 745, 40, 75, 32);
        Place(convert, MakeButton("コピー", () => { if (!string.IsNullOrEmpty(codeOut.Text)) Clipboard.SetText(codeOut.Text); }), 825, 40, 75, 32);
        Place(convert, MakeButton("保存", () => SaveTextFile(codeOut.Text, "converted-code.txt", "コード|*.txt;*.cs;*.py;*.cpp;*.java")), 905, 40, 75, 32);
        convert.Controls.Add(codeIn); convert.Controls.Add(codeOut); Place(convert, conversionStatus, 14, 310, 1140, 42);

        var workspace = Card("🧑‍💻 プログラム作成・AI生成／修正アシスト", 475);
        var workLang = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 170, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; workLang.Items.AddRange(langs); workLang.SelectedItem = "C#";
        var service = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 140, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; service.Items.AddRange(new object[] { "ChatGPT", "Google Gemini", "Claude" }); service.SelectedIndex = 0;
        var request = TextEntry("作りたいプログラムの要件・修正内容", true); request.SetBounds(14, 85, 350, 90); StyleInput(request);
        var code = TextEntry("ここにプログラムを自由に書けます…", true); code.SetBounds(14, 190, 555, 215); StyleInput(code); code.Font = new Font("Consolas", 10);
        var aiResult = TextEntry("外部AIの回答を確認してから貼り付けてください。", true); aiResult.SetBounds(590, 190, 570, 215); StyleInput(aiResult); aiResult.Font = new Font("Consolas", 10);
        var prompt = TextEntry("生成・修正・解説用プロンプト", true); prompt.SetBounds(385, 85, 775, 90); StyleInput(prompt);
        Place(workspace, new Label { Text = "作成言語", AutoSize = true, ForeColor = Color.Gainsboro }, 14, 45, 80, 25); Place(workspace, workLang, 94, 41, 170, 32);
        Place(workspace, new Label { Text = "外部AI", AutoSize = true, ForeColor = Color.Gainsboro }, 280, 45, 55, 25); Place(workspace, service, 335, 41, 140, 32);
        Place(workspace, MakeButton("🧪 サンプル", () => code.Text = SampleFor(workLang.Text)), 490, 41, 105, 32);
        workspace.Controls.Add(request); workspace.Controls.Add(prompt); workspace.Controls.Add(code); workspace.Controls.Add(aiResult);
        Place(workspace, MakeButton("✨ 新規生成プロンプト", () => prompt.Text = BuildCodePrompt("generate", workLang.Text, request.Text, code.Text)), 14, 415, 155, 32);
        Place(workspace, MakeButton("🛠 修正プロンプト", () => prompt.Text = BuildCodePrompt("fix", workLang.Text, request.Text, code.Text)), 174, 415, 125, 32);
        Place(workspace, MakeButton("🔎 解説プロンプト", () => prompt.Text = BuildCodePrompt("explain", workLang.Text, request.Text, code.Text)), 304, 415, 125, 32);
        Place(workspace, MakeButton("依頼文をコピー", () => { if (prompt.Text.Length > 0) Clipboard.SetText(prompt.Text); }), 434, 415, 105, 32);
        Place(workspace, MakeButton("依頼文をコピーしてAIを開く", () => { if (prompt.Text.Length == 0) prompt.Text = BuildCodePrompt("generate", workLang.Text, request.Text, code.Text); Clipboard.SetText(prompt.Text); OpenUrl(service.Text switch { "Google Gemini" => "https://gemini.google.com/app", "Claude" => "https://claude.ai/new", _ => "https://chatgpt.com/" }); }), 544, 415, 185, 32);
        Place(workspace, MakeButton("回答をエディターへ反映", () => { if (aiResult.Text.Trim().Length > 0) code.Text = aiResult.Text; }), 735, 415, 155, 32);
        Place(workspace, MakeButton("コードを保存", () => SaveTextFile(code.Text, "nexus-program.txt", "コード|*.txt;*.cs;*.py;*.cpp;*.java")), 895, 415, 100, 32);
        Place(workspace, MakeButton("コードをコピー", () => { if (code.Text.Length > 0) Clipboard.SetText(code.Text); }), 1000, 415, 110, 32);

        var workshop = Card("✦ NEXUS Assistant+ 言語設計工房", 440);
        var langName = TextEntry("例：NovaScript"); var paradigm = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 230, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; paradigm.Items.AddRange(new object[] { "マルチパラダイム", "手続き型", "オブジェクト指向", "関数型", "データ指向・並列処理", "教育向け" }); paradigm.SelectedIndex = 0;
        var typing = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 230, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; typing.Items.AddRange(new object[] { "静的型付け（型推論あり）", "動的型付け", "静的型付け（明示宣言）", "段階的型付け" }); typing.SelectedIndex = 0;
        var syntax = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 230, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White }; syntax.Items.AddRange(new object[] { "C系（波括弧とセミコロン）", "Python風（インデント）", "シンプルなインデント構文", "Lisp風（S式）" }); syntax.SelectedIndex = 0;
        var desc = TextEntry("言語の目的・特徴", true); var features = TextEntry("優先機能（例：非同期処理、日本語キーワード）");
        var specOut = TextEntry("生成された言語仕様", true); specOut.ReadOnly = true;
        var specPrompt = TextEntry("Assistant+用プロンプト", true); specPrompt.ReadOnly = true;
        Place(workshop, langName, 14, 44, 200, 30); Place(workshop, paradigm, 225, 44, 220, 30); Place(workshop, typing, 455, 44, 220, 30); Place(workshop, syntax, 685, 44, 230, 30); Place(workshop, features, 925, 44, 240, 30);
        desc.SetBounds(14, 83, 1145, 58); StyleInput(desc); workshop.Controls.Add(desc);
        specOut.SetBounds(14, 151, 565, 215); StyleInput(specOut); workshop.Controls.Add(specOut); specPrompt.SetBounds(590, 151, 570, 215); StyleInput(specPrompt); workshop.Controls.Add(specPrompt);
        Place(workshop, MakeButton("✨ 言語仕様を生成", () => specOut.Text = BuildLanguageSpec(langName.Text, paradigm.Text, typing.Text, syntax.Text, desc.Text, features.Text)), 14, 375, 135, 32);
        Place(workshop, MakeButton("🤖 Assistant+用プロンプト", () => specPrompt.Text = "以下の独自言語を実装してください。\n\n" + BuildLanguageSpec(langName.Text, paradigm.Text, typing.Text, syntax.Text, desc.Text, features.Text) + "\n\nコンパイラまたはインタープリター、テスト、サンプルを提示してください。"), 155, 375, 180, 32);
        Place(workshop, MakeButton("仕様をコピー", () => { if (specOut.Text.Length > 0) Clipboard.SetText(specOut.Text); }), 345, 375, 95, 32);
        Place(workshop, MakeButton("仕様を保存", () => SaveTextFile(specOut.Text, "language-spec.txt", "テキスト|*.txt")), 445, 375, 95, 32);
        flow.Controls.Add(convert); flow.Controls.Add(workspace); flow.Controls.Add(workshop); return flow;
    }

    private static string SampleFor(string language) => language switch
    {
        "Python" => "# NEXUS CodeBridge\nname = \"NEXUS\"\nprint(f\"Hello, {name}!\")\n",
        "JavaScript" => "// NEXUS CodeBridge\nconst name = \"NEXUS\";\nconsole.log(`Hello, ${name}!`);\n",
        "TypeScript" => "const name: string = \"NEXUS\";\nconsole.log(`Hello, ${name}!`);\n",
        "Java" => "public class Main {\n  public static void main(String[] args) {\n    String name = \"NEXUS\";\n    System.out.println(\"Hello, \" + name + \"!\");\n  }\n}\n",
        "Go" => "package main\nimport \"fmt\"\nfunc main() {\n  name := \"NEXUS\"\n  fmt.Println(\"Hello, \" + name + \"!\")\n}\n",
        "R" => "name <- \"NEXUS\"\ncat(paste0(\"Hello, \", name, \"!\\n\"))\n",
        "C" => "#include <stdio.h>\nint main(void) {\n  const char *name = \"NEXUS\";\n  printf(\"Hello, %s!\\n\", name);\n  return 0;\n}\n",
        "C#" => "using System;\nclass Program {\n  static void Main() {\n    string name = \"NEXUS\";\n    Console.WriteLine($\"Hello, {name}!\");\n  }\n}\n",
        "C++" => "#include <iostream>\n#include <string>\nint main() {\n  std::string name = \"NEXUS\";\n  std::cout << \"Hello, \" << name << \"!\" << std::endl;\n}\n",
        "Cython" => "# cython: language_level=3\nname = \"NEXUS\"\nprint(f\"Hello, {name}!\")\n",
        "Rust" => "fn main() {\n  let name = \"NEXUS\";\n  println!(\"Hello, {}!\", name);\n}\n",
        "PHP" => "<?php\n$name = \"NEXUS\";\necho \"Hello, \" . $name . \"!\\n\";\n?>\n",
        "HTML" => "<!doctype html>\n<html lang=\"ja\"><meta charset=\"utf-8\"><title>NEXUS</title><body><h1>Hello, NEXUS!</h1></body></html>",
        "BASIC" => "10 REM NEXUS CodeBridge\n20 LET NAME$ = \"NEXUS\"\n30 PRINT \"Hello, \"; NAME$; \"!\"\n40 END\n",
        "SQL" => "-- NEXUS CodeBridge SQL\nSELECT 'Hello, NEXUS!' AS message;\nSELECT CURRENT_DATE AS today;\n",
        "Elixir" => "name = \"NEXUS\"\nIO.puts(\"Hello, #{name}!\")\n",
        "Haskell" => "main = do\n  let name = \"NEXUS\"\n  putStrLn (\"Hello, \" ++ name ++ \"!\")\n",
        _ => "// NEXUS CodeBridge starter\n"
    };

    private static string ConvertCode(string source, string from, string to)
    {
        if (string.IsNullOrWhiteSpace(source)) return "";
        if (from == to) return source;
        var result = new StringBuilder();
        foreach (string raw in source.Replace("\r", "").Split('\n'))
        {
            string line = raw.Trim(); if (line.Length == 0) { result.AppendLine(); continue; }
            if (line.StartsWith("//") || line.StartsWith("#") || line.StartsWith("--")) { result.AppendLine(ConvertComment(line, to)); continue; }
            var variable = Regex.Match(line, @"^(?:(?:let|const|var)\s+|(?:string|String|int|double|float|bool|boolean|var)\s+|(?:let\s+mut\s+))?([A-Za-z_]\w*)\s*(?::\s*[\w<>]+)?\s*(?:<-|:=|=)\s*(.+?);?$");
            var print = Regex.Match(line, @"^(?:print|console\.log|Console\.WriteLine|System\.out\.println|fmt\.Println|IO\.puts|echo|cat|println!)\s*\((.*)\)\s*;?$");
            if (print.Success) { string arg = print.Groups[1].Value.Trim(); result.AppendLine(EmitPrint(arg, to)); continue; }
            if (variable.Success && !line.Contains("=>") && !line.Contains("==")) { result.AppendLine(EmitVariable(variable.Groups[1].Value, variable.Groups[2].Value.Trim().TrimEnd(';'), to)); continue; }
            if (Regex.IsMatch(line, @"^\s*(?:return|break|continue)\b")) { result.AppendLine(line); continue; }
            result.AppendLine("// 要確認・手動変換: " + raw.Trim());
        }
        return result.ToString();
    }

    private static string ConvertComment(string line, string to)
    {
        string body = Regex.Replace(line, @"^(//|#|--|/\*)\s?", "").TrimEnd('*', '/');
        return to switch { "Python" or "R" or "Cython" or "BASIC" => "# " + body, "SQL" => "-- " + body, "HTML" => "<!-- " + body + " -->", _ => "// " + body };
    }
    private static string EmitVariable(string name, string expression, string to)
    {
        string expr = expression.Trim(); bool str = expr.StartsWith("\"") || expr.StartsWith("'") || expr.StartsWith("`"); bool boolean = expr is "true" or "false" or "TRUE" or "FALSE"; bool floating = double.TryParse(expr, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out double d) && expr.Contains('.');
        if (to == "C#") return $"{(str ? "string" : boolean ? "bool" : floating ? "double" : "var")} {name} = {expr};";
        if (to == "C") return $"{(str ? "const char*" : boolean ? "int" : floating ? "double" : "int")} {name} = {expr};";
        if (to == "C++") return $"{(str ? "std::string" : boolean ? "bool" : floating ? "double" : "auto")} {name} = {expr};";
        if (to == "Java") return $"{(str ? "String" : boolean ? "boolean" : floating ? "double" : "int")} {name} = {expr};";
        if (to == "Go") return $"{name} := {expr}";
        if (to == "Rust") return $"let {(str ? "" : "mut ")}{name} = {expr};";
        if (to == "R") return $"{name} <- {expr}";
        if (to == "PHP") return $"${name} = {expr};";
        if (to == "SQL") return $"SELECT {expr} AS {name};";
        if (to == "Elixir") return $"{name} = {expr}";
        if (to == "Haskell") return $"let {name} = {expr}";
        if (to == "BASIC") return $"LET {name.ToUpperInvariant()} = {expr}";
        return $"let {name} = {expr};";
    }
    private static string EmitPrint(string arg, string to)
    {
        if (to == "Python" || to == "Cython") return $"print({arg})";
        if (to == "JavaScript" || to == "TypeScript") return $"console.log({arg});";
        if (to == "C#") return $"Console.WriteLine({arg});";
        if (to == "Java") return $"System.out.println({arg});";
        if (to == "Go") return $"fmt.Println({arg})";
        if (to == "C") return $"printf(\"%s\\n\", {arg});";
        if (to == "C++") return $"std::cout << {arg} << std::endl;";
        if (to == "Rust") return $"println!(\"{{}}\", {arg});";
        if (to == "PHP") return $"echo {arg};";
        if (to == "R") return $"cat({arg}, \"\\n\")";
        if (to == "BASIC") return $"PRINT {arg}";
        if (to == "SQL") return $"SELECT {arg} AS output;";
        if (to == "Elixir") return $"IO.puts({arg})";
        if (to == "Haskell") return $"putStrLn {arg}";
        return $"print({arg});";
    }
    private static string BuildCodePrompt(string mode, string lang, string request, string code)
    {
        string action = mode switch { "fix" => "次のコードを修正してください。既存の仕様を保ち、変更点を説明してください。", "explain" => "次のコードを初心者にもわかるように解説してください。", _ => "以下の要件を満たすプログラムを新規作成してください。" };
        return $"あなたは経験豊富なソフトウェアエンジニアです。\n{action}\n対象言語：{lang}\n要件・修正内容：{(string.IsNullOrWhiteSpace(request) ? "不足する仕様は安全な仮定を明記してください。" : request)}\n\nコード：\n{code}\n\n入力検証、エラー処理、セキュリティ、保守性に配慮し、完成コードと変更点・実行方法・テスト例を日本語で提示してください。";
    }
    private static string BuildLanguageSpec(string name, string paradigm, string typing, string syntax, string desc, string features)
    {
        if (string.IsNullOrWhiteSpace(name)) name = "NovaScript";
        string grammar = syntax.StartsWith("Python") || syntax.Contains("インデント") ? "program ::= statement*\nstatement ::= variable | print | if-block | function\nvariable ::= IDENT '=' expression\nprint ::= 'print' '(' expression ')'" : syntax.StartsWith("Lisp") ? "program ::= expression*\nexpression ::= '(' IDENT expression* ')' | literal | IDENT" : "program ::= statement*\nstatement ::= variable | print | if-block | function\nvariable ::= ('let' | 'const') IDENT '=' expression ';'\nprint ::= 'print' '(' expression ')' ';'\nif-block ::= 'if' '(' expression ')' '{' statement* '}'";
        return $"{name} — 言語設計書（NEXUS Assistant+）\n\n1. 言語コンセプト\n目的：{(string.IsNullOrWhiteSpace(desc) ? "用途を定義してください。" : desc)}\nパラダイム：{paradigm}\n型システム：{typing}\n文法方式：{syntax}\n優先機能：{features}\n\n2. コア構文案\n変数宣言：let name = value\n出力：print(value)\n条件分岐：if condition {{ ... }}\n関数：fn name(args) {{ ... }}\n\n3. 文法（EBNFたたき台）\n{grammar}\nIDENT ::= letter (letter | digit | '_')*\nexpression ::= literal | IDENT | function-call | operator-expression\nliteral ::= number | string | boolean\n\n4. サンプルプログラム\nlet message = \"Hello, {name}!\"\nprint(message)\n\n5. 実装メモ\nこの仕様はプロトタイプです。字句解析・構文解析・型検査・実行系・テストスイートを設計し、仕様を検証してください。";
    }
#endregion

#region Security, privacy, URL checker
    private Control BuildSecurityPage()
    {
        var flow = PageFlow();
        var urlCard = Card("🔎 NEXUS URLチェッカー — ローカル形式検査", 335);
        var urlInput = TextEntry("例：https://example.com/"); Place(urlCard, urlInput, 14, 45, 920, 34);
        var urlResult = new Label { Text = "URLを入力して「ローカル検査」を押してください。", ForeColor = Color.LightSkyBlue, AutoSize = false };
        Place(urlCard, MakeButton("🛡️ ローカル検査", () => { var check = CheckUrl(urlInput.Text); urlResult.Text = check.Report; }), 945, 45, 140, 34);
        Place(urlCard, MakeButton("消去", () => { urlInput.Clear(); urlResult.Text = "URLを入力してください。"; }), 1090, 45, 75, 34);
        Place(urlCard, urlResult, 14, 95, 1140, 215); flow.Controls.Add(urlCard);

        var report = Card("🛡️ セキュリティ・プライバシーレポート", 300);
        var output = TextEntry("この端末の設定・構成をローカル診断します。", true); output.SetBounds(14, 45, 1145, 170); StyleInput(output); output.ReadOnly = true; report.Controls.Add(output);
        Place(report, MakeButton("🔍 今すぐチェック", () => output.Text = GenerateSecurityReport()), 14, 225, 130, 32);
        Place(report, MakeButton("⬇ レポート保存", () => SaveTextFile(output.Text, "NEXUS-security-report.txt", "テキスト|*.txt")), 150, 225, 120, 32);
        Place(report, MakeButton("📋 コピー", () => { if (output.Text.Length > 0) Clipboard.SetText(output.Text); }), 275, 225, 90, 32);
        flow.Controls.Add(report);

        var privacy = Card("🔐 セキュリティとプライバシーについて", 180);
        Place(privacy, new Label { Text = "・メモ、Todo、予定、掲示板、設定はこのPCのユーザープロファイル内に保存されます。\n・天気更新はOpen-Meteoへ直接通信します。初期状態では自動更新を停止します。\n・URL検査はルールベースの参考値です。安全性を保証するものではありません。\n・画面保護はNEXUSウィンドウ内のみで、OSロックやスクリーンショット防止ではありません。", ForeColor = Color.Gainsboro, AutoSize = false }, 14, 45, 1140, 110);
        flow.Controls.Add(privacy); return flow;
    }

    private (int Score, string Report) CheckUrl(string raw)
    {
        raw = raw.Trim(); if (raw.Length == 0) return (0, "URLが入力されていません。");
        int score = 0; var reasons = new List<string>();
        if (!raw.Contains("://")) raw = "https://" + raw;
        if (!Uri.TryCreate(raw, UriKind.Absolute, out var uri) || (uri.Scheme != "https" && uri.Scheme != "http")) return (100, "URL形式を解析できません。正しいhttp/https URLを入力してください。\n形式上の注意度: 100/100");
        if (uri.Scheme == "http") { score += 15; reasons.Add("HTTPSではなくHTTPです（暗号化されません）。"); }
        if (!string.IsNullOrEmpty(uri.UserInfo)) { score += 25; reasons.Add("URLにユーザー情報（@より前）が含まれています。"); }
        if (uri.HostNameType == UriHostNameType.IPv4 || uri.HostNameType == UriHostNameType.IPv6) { score += 20; reasons.Add("ホスト名がIPアドレスです。"); }
        if (uri.Host.StartsWith("xn--", StringComparison.OrdinalIgnoreCase) || uri.IdnHost.Contains("xn--", StringComparison.OrdinalIgnoreCase)) { score += 15; reasons.Add("国際化ドメインのPunycode表記を含みます。"); }
        if (uri.Host.Count(c => c == '.') >= 4) { score += 8; reasons.Add("サブドメイン階層が多くなっています。"); }
        if (uri.Host.Length > 45) { score += 8; reasons.Add("ホスト名が非常に長いです。"); }
        string full = raw.ToLowerInvariant();
        foreach (string word in new[] { "login", "verify", "account", "secure", "update", "password", "wallet", "signin" }) if (uri.Host.Contains(word)) { score += 4; reasons.Add("ホスト名に認証・アカウント関連語が含まれます: " + word); }
        if (Regex.IsMatch(full, @"%[0-9a-f]{2}", RegexOptions.IgnoreCase)) { score += 5; reasons.Add("パーセントエンコードを含みます。"); }
        if (raw.Length > 180) { score += 5; reasons.Add("URL全体が長いです。"); }
        score = Math.Clamp(score, 0, 100);
        string level = score >= 60 ? "高め" : score >= 30 ? "注意" : score > 0 ? "低め" : "低い";
        var sb = new StringBuilder(); sb.AppendLine("入力URL: " + raw); sb.AppendLine("ホスト名: " + uri.Host); sb.AppendLine("形式上の注意度: " + score + "/100（" + level + "）"); sb.AppendLine("この数値はルールベースの目安であり、サイトの安全性を測定したものではありません。"); sb.AppendLine(); sb.AppendLine("検査理由:"); if (reasons.Count == 0) sb.AppendLine("・この検査ルールでは、目立つ形式上の注意点は検出されませんでした。"); else foreach (var r in reasons) sb.AppendLine("・" + r);
        sb.AppendLine("\n注意：フィッシングやマルウェアの存在を確定する検査ではありません。送信元・証明書・内容を別途確認してください。");
        return (score, sb.ToString());
    }

    private string GenerateSecurityReport()
    {
        int bytes = Encoding.UTF8.GetByteCount(Store.Serialize(_state));
        int invalidApps = _state.Apps.Count(a => !NormalizeUrl(a.Url, out _));
        var sb = new StringBuilder(); sb.AppendLine("NEXUS SUPER4.1 — ローカルセキュリティ診断"); sb.AppendLine("実行日時: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); sb.AppendLine("保存先: " + Store.Root); sb.AppendLine();
        sb.AppendLine("[保存データ] "); sb.AppendLine("メモ: " + _state.Memos.Count + "件 / Todo日付: " + _state.Todos.Count + "件 / 予定: " + _state.Events.Count + "件 / 掲示板: " + _state.Board.Count + "件"); sb.AppendLine("アプリ・リンク: " + _state.Apps.Count + "件（形式不正 " + invalidApps + "件）"); sb.AppendLine("状態ファイル概算: " + (bytes / 1024.0).ToString("0.0") + " KiB");
        sb.AppendLine("\n[プライバシー設定]"); sb.AppendLine("天気の自動取得: " + (_state.AutoWeather ? "許可" : "停止（手動更新のみ）")); sb.AppendLine("画面保護: " + (_state.ScreenProtect ? "有効" : "無効")); sb.AppendLine("通信匿名モード: " + (_state.AnonCommunication ? "有効（外部URL起動をブロック）" : "無効")); sb.AppendLine("プライバシーシールド: " + (_state.PrivacyShield ? "有効" : "無効"));
        sb.AppendLine("\n[実行環境]"); sb.AppendLine("OS: " + Environment.OSVersion); sb.AppendLine(".NET: " + Environment.Version); sb.AppendLine("プロセス: " + Environment.ProcessId); sb.AppendLine("メモリ使用量: " + (Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024) + " MiB"); sb.AppendLine("アプリ実行時エラー記録: " + _errorCount + "件");
        sb.AppendLine("\n[注意事項]"); sb.AppendLine("・このレポートはNEXUS内でローカル生成され、外部送信されません。"); sb.AppendLine("・データ本文、メモ内容、Todo本文、掲示板本文、お絵かき画像はレポートに含めていません。"); sb.AppendLine("・URL検査と設定確認は簡易診断であり、完全なセキュリティ監査ではありません。");
        return sb.ToString();
    }
#endregion

#region Settings, privacy and backup
    private Control BuildSettingsPage()
    {
        var flow = PageFlow();
        var appearance = Card("🎨 外観・表示制御", 205);
        var accent = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 240, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        accent.Items.AddRange(new object[] { "シアン #39D8FF", "ブルー #589BFF", "パープル #B78BFF", "ピンク #FF78C9", "グリーン #64E5AF", "オレンジ #FFB36B" }); accent.SelectedIndex = Math.Max(0, Array.FindIndex(new[] { "#39D8FF", "#589BFF", "#B78BFF", "#FF78C9", "#64E5AF", "#FFB36B" }, x => x.Equals(_state.Accent, StringComparison.OrdinalIgnoreCase)));
        var fast = new CheckBox { Text = "高速・軽量モード", Checked = _state.FastMode, AutoSize = true, ForeColor = Color.White };
        var reduce = new CheckBox { Text = "アニメーションを抑制", Checked = _state.ReducedMotion, AutoSize = true, ForeColor = Color.White };
        Place(appearance, new Label { Text = "アクセント色", AutoSize = true, ForeColor = Color.Gainsboro }, 14, 48, 100, 24); Place(appearance, accent, 115, 42, 240, 32); Place(appearance, fast, 375, 48, 180, 25); Place(appearance, reduce, 565, 48, 210, 25);
        Place(appearance, MakeButton("設定を適用・保存", () => { string[] cols = { "#39D8FF", "#589BFF", "#B78BFF", "#FF78C9", "#64E5AF", "#FFB36B" }; _state.Accent = cols[Math.Max(0, accent.SelectedIndex)]; _state.FastMode = fast.Checked; _state.ReducedMotion = reduce.Checked; SaveState(); ApplyTheme(); }), 14, 95, 145, 32);
        Place(appearance, MakeButton("背景画像を選ぶ", ChooseWallpaper), 165, 95, 125, 32);
        Place(appearance, MakeButton("既定の宇宙背景", () => { _wallpaper?.Dispose(); _wallpaper = null; _state.WallpaperFile = null; SaveState(); Invalidate(); }), 295, 95, 135, 32);
        flow.Controls.Add(appearance);

        var privacy = Card("🕵️ プライバシー強化", 270);
        var auto = new CheckBox { Text = "天気の自動取得を許可（初期設定はオフ）", Checked = _state.AutoWeather, AutoSize = true, ForeColor = Color.White };
        var scr = new CheckBox { Text = "画面プライバシー保護（ボタン操作で画面を一時的に隠す）", Checked = _state.ScreenProtect, AutoSize = true, ForeColor = Color.White };
        var anon = new CheckBox { Text = "通信匿名モード（外部サイト・通信をブロック）", Checked = _state.AnonCommunication, AutoSize = true, ForeColor = Color.White };
        var shield = new CheckBox { Text = "プライバシーシールド（入力値を画面上で保護する設定）", Checked = _state.PrivacyShield, AutoSize = true, ForeColor = Color.White };
        Place(privacy, auto, 14, 45, 640, 26); Place(privacy, scr, 14, 78, 740, 26); Place(privacy, anon, 14, 111, 650, 26); Place(privacy, shield, 14, 144, 700, 26);
        Place(privacy, MakeButton("設定を保存", () =>
        {
            _state.AutoWeather = auto.Checked; _state.ScreenProtect = scr.Checked; _state.AnonCommunication = anon.Checked; _state.PrivacyShield = shield.Checked; SaveState();
            if (!scr.Checked) HideSleepOrPrivacyOverlay(false);
            if (_state.AutoWeather && !_state.AnonCommunication)
            {
                _weatherTimer.Start();
                if (_weatherPrefectureControl != null && _weatherResultControl != null && _weatherStatusControl != null)
                    _ = LoadWeatherAsync(_weatherPrefectureControl, _weatherResultControl, _weatherStatusControl);
            }
            else _weatherTimer.Stop();
        }), 14, 187, 105, 32);
        Place(privacy, MakeButton("🔒 画面保護をテスト", ShowPrivacyOverlay), 125, 187, 145, 32);
        Place(privacy, MakeButton("🗑 NEXUS保存データを消去", ClearAllData), 280, 187, 190, 32);
        Place(privacy, new Label { Text = "この設定はNEXUSアプリ内の動作を制御します。OS全体の通信、画面、端末ロックは変更しません。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 14, 225, 1100, 27);
        flow.Controls.Add(privacy);

        var backup = Card("💾 設定・メモの一括バックアップ", 235);
        var encrypt = new CheckBox { Text = "AES-256-GCMで暗号化してエクスポート", AutoSize = true, ForeColor = Color.White };
        var pass = TextEntry("パスフレーズ（12文字以上）"); pass.UseSystemPasswordChar = true; pass.Width = 300;
        Place(backup, encrypt, 14, 47, 330, 25); Place(backup, pass, 350, 42, 300, 32);
        Place(backup, MakeButton("⬇ エクスポート", () => ExportBackup(encrypt.Checked, pass.Text)), 14, 95, 130, 34);
        Place(backup, MakeButton("⬆ インポート", () => ImportBackup(pass.Text)), 150, 95, 115, 34);
        Place(backup, new Label { Text = "暗号化ファイルの復元には、エクスポート時と同じパスフレーズが必要です。パスフレーズはアプリ内に保存しません。\nバックアップは端末内の任意の場所に保存してください。ファイル共有時は個人情報に注意してください。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 14, 145, 1120, 55);
        flow.Controls.Add(backup);

        var legal = Card("📜 利用規約・著作権・出典", 325);
        var terms = TextEntry(TermsText, true); terms.SetBounds(14, 40, 1145, 265); StyleInput(terms); terms.ReadOnly = true; legal.Controls.Add(terms); flow.Controls.Add(legal);
        return flow;
    }

    private static string TermsText => "NEXUS SUPER4.1 利用規約\r\n制定日：2026年10月25日\r\n\r\n" +
        "第1条（提供内容）\r\n本ツールは、検索、ブックマーク、時計、天気、メモ、Todo、予定表、翻訳、音楽・BGM、お絵かき、ゲームなどの機能をひとつの画面で提供します。機能は予告なく追加・変更・終了することがあります。\r\n\r\n" +
        "第2条（利用範囲）\r\n本ツールは、個人の非営利目的での利用に限ります。天気データの提供元が非営利利用に限って無償提供しているため、商用での利用はできません。\r\n\r\n" +
        "第3条（禁止事項）\r\n法令または公序良俗に反する行為、他者の著作権・プライバシーその他の権利を侵害する行為、本ツールの無断での再配布・販売、または改変したものの公開（制作者が許可した場合を除く）、外部サービスに過度な負荷をかける行為、他者になりすます行為、不正アクセスその他の運営を妨げる行為を禁止します。本ツールのプログラム、画面デザイン、文章の著作権は、GitHubアカウント『kinokokenatto』に帰属します。\r\n\r\n" +
        "第4条（データの取り扱い）\r\nメモ、Todo、予定、設定、お絵かきなどのデータは、利用端末内に保存され、本ツール自身は制作者や第三者のサーバーへ送信しません。保存データは通常の状態では暗号化されません。共有端末では秘密情報を保存しないでください。データの損失に備え、利用者自身でバックアップしてください。天気情報は手動更新、または自動取得を許可した場合にOpen-Meteoへ直接通信します。翻訳サイトを開くと、入力文章が各翻訳サービスへ送信されます。\r\n\r\n" +
        "第5条（外部サービス・リンク）\r\n外部サイト・サービスの内容、利用条件、個人情報の取り扱いは各提供者の定めに従います。本ツールと各社との間に提携・後援・推奨などの関係はありません。\r\n\r\n" +
        "第6条（情報の正確性）\r\n天気、ニュースなどの表示内容は参考情報であり、正確性・完全性・即時性を保証しません。\r\n\r\n" +
        "第7条（免責）\r\n本ツールは現状のまま提供され、動作、安全性、特定の目的への適合性を保証しません。利用または利用できないことにより生じた損害について、法令で許される範囲で制作者は責任を負いません。\r\n\r\n" +
        "第8条（規約の変更）\r\n本規約は必要に応じて変更することがあります。変更後の規約は本ツール上に掲示した時点から効力を生じます。\r\n\r\n第9条（準拠法）\r\n本規約は日本法に準拠します。\r\n\r\n" +
        "© 著作権・出典\r\nプログラム、画面デザイン、文章の著作権はGitHubアカウント『kinokokenatto』に帰属します。利用者が作成したメモ、予定、お絵かき等の権利は利用者に帰属します。Google、Microsoft、YouTube、DeepL、ChatGPT、Claude等の名称・ロゴは各社の商標です。天気：Open-Meteo（CC BY 4.0、非営利利用の無償API）。ニュース記事の著作権は各報道機関に帰属します。";

    private Bitmap? _wallpaper;
    private void ChooseWallpaper()
    {
        using var d = new OpenFileDialog { Filter = "画像ファイル|*.jpg;*.jpeg;*.png;*.bmp" }; if (d.ShowDialog() != DialogResult.OK) return;
        try
        {
            Directory.CreateDirectory(Store.Root);
            string ext = Path.GetExtension(d.FileName).ToLowerInvariant(); if (!new[] { ".jpg", ".jpeg", ".png", ".bmp" }.Contains(ext)) throw new InvalidDataException("対応していない画像形式です。");
            string target = Path.Combine(Store.Root, "nexus-wallpaper" + ext); File.Copy(d.FileName, target, true);
            _wallpaper?.Dispose(); _wallpaper = new Bitmap(target); _state.WallpaperFile = target; SaveState(); Invalidate();
        }
        catch (Exception ex) { MessageBox.Show("画像を開けません: " + ex.Message); }
    }
    private void ApplyTheme() { BackColor = Bg; ForeColor = Color.White; foreach (TabPage p in _tabs.TabPages) { p.BackColor = Bg; p.ForeColor = Color.White; } Invalidate(); }
    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (_wallpaper != null) { e.Graphics.DrawImage(_wallpaper, ClientRectangle); using var overlay = new SolidBrush(Color.FromArgb(110, 2, 7, 23)); e.Graphics.FillRectangle(overlay, ClientRectangle); }
    }
    private void ExportBackup(bool encrypted, string passphrase)
    {
        try
        {
            string json = Store.Serialize(_state); string payload = json;
            if (encrypted)
            {
                if (passphrase.Length < 12) { MessageBox.Show("暗号化には12文字以上のパスフレーズが必要です。"); return; }
                payload = EncryptBackup(json, passphrase);
            }
            using var d = new SaveFileDialog { Filter = "NEXUSバックアップ|*.json", FileName = "NEXUS-backup-" + DateTime.Now.ToString("yyyy-MM-dd") + (encrypted ? "-encrypted" : "") + ".json" };
            if (d.ShowDialog() == DialogResult.OK) { File.WriteAllText(d.FileName, payload, new UTF8Encoding(false)); MessageBox.Show(encrypted ? "暗号化バックアップを書き出しました。パスフレーズは保存されません。" : "バックアップを書き出しました。JSON自体は暗号化されていません。"); }
        }
        catch (Exception ex) { MessageBox.Show("エクスポートできませんでした: " + ex.Message); }
    }
    private sealed class EncryptedBackup { public string Format { get; set; } = "NEXUS_BACKUP_AES_GCM"; public int Version { get; set; } = 1; public string Salt { get; set; } = ""; public string Nonce { get; set; } = ""; public string Tag { get; set; } = ""; public string Ciphertext { get; set; } = ""; }
    private static string EncryptBackup(string plain, string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(16), nonce = RandomNumberGenerator.GetBytes(12), key = Rfc2898DeriveBytes.Pbkdf2(password, salt, 310000, HashAlgorithmName.SHA256, 32), bytes = Encoding.UTF8.GetBytes(plain), cipher = new byte[bytes.Length], tag = new byte[16];
        using (var aes = new AesGcm(key, 16)) aes.Encrypt(nonce, bytes, cipher, tag);
        return JsonSerializer.Serialize(new EncryptedBackup { Salt = Convert.ToBase64String(salt), Nonce = Convert.ToBase64String(nonce), Tag = Convert.ToBase64String(tag), Ciphertext = Convert.ToBase64String(cipher) }, new JsonSerializerOptions { WriteIndented = true });
    }
    private static string DecryptBackup(string source, string password)
    {
        using var doc = JsonDocument.Parse(source); if (!doc.RootElement.TryGetProperty("Format", out var fmt) || fmt.GetString() != "NEXUS_BACKUP_AES_GCM") return source;
        var b = JsonSerializer.Deserialize<EncryptedBackup>(source) ?? throw new InvalidDataException("暗号化バックアップの形式が不正です。");
        byte[] salt = Convert.FromBase64String(b.Salt), nonce = Convert.FromBase64String(b.Nonce), tag = Convert.FromBase64String(b.Tag), cipher = Convert.FromBase64String(b.Ciphertext), plain = new byte[cipher.Length];
        byte[] key = Rfc2898DeriveBytes.Pbkdf2(password, salt, 310000, HashAlgorithmName.SHA256, 32); using var aes = new AesGcm(key, 16); aes.Decrypt(nonce, cipher, tag, plain); return Encoding.UTF8.GetString(plain);
    }
    private void ImportBackup(string passphrase)
    {
        using var d = new OpenFileDialog { Filter = "NEXUSバックアップ|*.json" }; if (d.ShowDialog() != DialogResult.OK) return;
        try
        {
            string raw = File.ReadAllText(d.FileName, Encoding.UTF8); string plain = raw;
            if (raw.Contains("NEXUS_BACKUP_AES_GCM", StringComparison.Ordinal)) { if (passphrase.Length < 1) { MessageBox.Show("復元用パスフレーズを入力してください。"); return; } plain = DecryptBackup(raw, passphrase); }
            var restored = Store.Deserialize(plain);
            if (MessageBox.Show($"バックアップを復元しますか？\nメモ {restored.Memos.Count}件 / Todo日付 {restored.Todos.Count}件 / 予定 {restored.Events.Count}件 / 掲示板 {restored.Board.Count}件\n現在のデータは置き換えられます。", "復元確認", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes) return;
            Store.Save(restored); MessageBox.Show("復元しました。アプリを再起動します。"); Application.Restart();
        }
        catch (CryptographicException) { MessageBox.Show("復号に失敗しました。パスフレーズを確認してください。"); }
        catch (Exception ex) { MessageBox.Show("復元できませんでした: " + ex.Message); }
    }
    private void ClearAllData()
    {
        if (MessageBox.Show("NEXUS内のメモ、Todo、予定、掲示板、アプリ構成、設定、お絵かきデータをすべて削除します。先にバックアップしましたか？", "全データ削除", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes) return;
        try { if (File.Exists(Store.StatePath)) File.Delete(Store.StatePath); MessageBox.Show("保存データを削除しました。アプリを再起動します。"); Application.Restart(); } catch (Exception ex) { MessageBox.Show("削除できません: " + ex.Message); }
    }
#endregion

#region Developer mode, system tools and local assistant
    private Control BuildDeveloperPage()
    {
        var flow = PageFlow();
        var diag = TextEntry("診断を実行すると、この端末のローカル設定と構成概要を表示します。", true);
        diag.SetBounds(14, 43, 1145, 165); StyleInput(diag); diag.ReadOnly = true;
        var dev = Card("⚠ NEXUS 開発者モード・管理センター", 245);
        Place(dev, new Label { Text = "診断・アプリ検査・ローカルデータ管理・動作制御を行います。任意のJavaScript実行やOS全体の設定変更は行いません。\n管理者権限はこのアプリを開いている間だけ有効です。変更・削除の前にバックアップしてください。", ForeColor = Color.FromArgb(240, 220, 180), AutoSize = false }, 14, 45, 1140, 70);
        var devStatus = new Label { Text = "開発者モード：停止中", ForeColor = Color.LightSkyBlue, AutoSize = true };
        Place(dev, devStatus, 14, 127, 250, 24);
        Place(dev, MakeButton("🛠 開発者モードを有効化", () => { _devEnabled = true; devStatus.Text = "開発者モード：有効（このセッションのみ）"; SetStatus("開発者モードを有効化しました。"); }), 14, 160, 175, 32);
        Place(dev, MakeButton("停止", () => { _devEnabled = false; _adminEnabled = false; devStatus.Text = "開発者モード：停止中"; }), 195, 160, 75, 32);
        Place(dev, MakeButton("🔍 診断を実行", () => { if (!_devEnabled) { MessageBox.Show("先に開発者モードを有効にしてください。"); return; } diag.Text = GenerateSecurityReport(); }), 280, 160, 125, 32);
        var adminStatus = new Label { Text = "管理者権限は無効です。", ForeColor = Color.LightGreen, AutoSize = true }; Place(dev, adminStatus, 755, 164, 350, 24);
        Place(dev, MakeButton("🛡 管理者権限を有効化", () => { if (!_devEnabled) { MessageBox.Show("先に開発者モードを有効にしてください。"); return; } _adminEnabled = true; adminStatus.Text = "ADMIN ACTIVE · THIS SESSION"; }), 415, 160, 175, 32);
        Place(dev, MakeButton("🔒 管理者権限を解除", () => { _adminEnabled = false; adminStatus.Text = "管理者権限は無効です。"; }), 595, 160, 145, 32);
        flow.Controls.Add(dev);

        var diagnostics = Card("🔬 診断レポート", 260);
        diagnostics.Controls.Add(diag);
        Place(diagnostics, MakeButton("レポート保存", () => SaveTextFile(diag.Text, "NEXUS-diagnostic.txt", "テキスト|*.txt")), 14, 215, 110, 32);
        Place(diagnostics, MakeButton("保存データを表示", () => { if (!RequireAdmin()) return; diag.Text = Store.Serialize(_state); }), 130, 215, 145, 32);
        Place(diagnostics, MakeButton("データ件数を表示", () => diag.Text = GetSystemMetrics()), 280, 215, 130, 32);
        flow.Controls.Add(diagnostics);

        var command = Card("⌨ NEXUS 管理コマンド（許可リスト方式）", 210);
        var cmd = TextEntry("help / status / keys / fast on / privacy on / network off");
        var commandOutput = TextEntry("実行結果", true); commandOutput.ReadOnly = true; commandOutput.SetBounds(14, 85, 1145, 82); StyleInput(commandOutput);
        Place(command, cmd, 14, 45, 790, 32); Place(command, MakeButton("実行", () => commandOutput.Text = RunAdminCommand(cmd.Text)), 815, 45, 80, 32); command.Controls.Add(commandOutput); flow.Controls.Add(command);

        var sleep = Card("🌙 おやすみ制限（セルフコントロール）", 205);
        var enabled = new CheckBox { Text = "おやすみ制限を有効にする", Checked = _state.SleepEnabled, ForeColor = Color.White, AutoSize = true };
        var start = TextEntry("22:00"); start.Text = _state.SleepStart; var end = TextEntry("07:00"); end.Text = _state.SleepEnd;
        Place(sleep, enabled, 14, 45, 280, 25); Place(sleep, new Label { Text = "開始時刻", AutoSize = true, ForeColor = Color.Gainsboro }, 14, 85, 80, 24); Place(sleep, start, 100, 80, 90, 30); Place(sleep, new Label { Text = "終了時刻", AutoSize = true, ForeColor = Color.Gainsboro }, 205, 85, 80, 24); Place(sleep, end, 290, 80, 90, 30);
        Place(sleep, MakeButton("💾 設定を保存", () => { if (!TimeSpan.TryParse(start.Text, out _) || !TimeSpan.TryParse(end.Text, out _) || start.Text == end.Text) { MessageBox.Show("開始・終了時刻はHH:mm形式で、異なる時刻を指定してください。"); return; } _state.SleepEnabled = enabled.Checked; _state.SleepStart = start.Text; _state.SleepEnd = end.Text; SaveState(); CheckSleepRestriction(); }), 14, 125, 130, 32);
        Place(sleep, MakeButton("🌙 休憩画面を1分テスト", () => ShowSleepOverlay(true)), 150, 125, 165, 32);
        Place(sleep, new Label { Text = "指定時間になるとこのアプリを休憩画面で覆います。OSロックや端末全体の制限ではありません。", ForeColor = Color.LightSkyBlue, AutoSize = false }, 325, 125, 800, 32);
        flow.Controls.Add(sleep);

        var source = Card("🧑‍💻 C#ソース情報", 125);
        Place(source, new Label { Text = "このプロジェクトはWindows FormsのC#で実装しています。HTML/JavaScriptの実行・埋め込みはありません。Program.csを編集し、.NET 8 SDKでビルドしてください。", ForeColor = Color.Gainsboro, AutoSize = false }, 14, 45, 1140, 55);
        Place(source, MakeButton("保存フォルダーを開く", () => Process.Start(new ProcessStartInfo(Store.Root) { UseShellExecute = true })), 14, 88, 165, 30); flow.Controls.Add(source);
        return flow;
    }

    private bool RequireAdmin()
    {
        if (_devEnabled && _adminEnabled) return true;
        MessageBox.Show("開発者モードと管理者権限を有効にしてください。"); return false;
    }
    private string RunAdminCommand(string command)
    {
        string c = command.Trim().ToLowerInvariant();
        if (c == "help") return "許可コマンド:\nhelp — 一覧\nstatus — システム状態\nkeys — 保存データの項目一覧\nfast on/off — 高速モード\nprivacy on/off — 画面保護\nnetwork on/off — 天気の自動通信\naccent cyan/blue/purple/pink — アクセント色";
        if (c == "status") return GetSystemMetrics();
        if (c == "keys") return "Apps / Memos / Todos / Events / Board / WeatherPrefecture / privacy settings / sleep settings / Drawing";
        if (!RequireAdmin()) return "管理者権限が必要です。";
        if (c == "fast on") _state.FastMode = true; else if (c == "fast off") _state.FastMode = false;
        else if (c == "privacy on") _state.ScreenProtect = true; else if (c == "privacy off") _state.ScreenProtect = false;
        else if (c == "network on") _state.AutoWeather = true; else if (c == "network off") _state.AutoWeather = false;
        else if (c.StartsWith("accent ")) { _state.Accent = c[7..] switch { "cyan" => "#39D8FF", "blue" => "#589BFF", "purple" => "#B78BFF", "pink" => "#FF78C9", _ => _state.Accent }; }
        else return "不明なコマンドです。helpで一覧を確認してください。";
        SaveState(); ApplyTheme(); return "設定を適用しました。";
    }

    private void OpenDeveloper()
    {
        if (_tabs.TabPages.Count >= 9) _tabs.SelectedIndex = 8;
    }

    private string GetSystemMetrics()
    {
        int bytes = Encoding.UTF8.GetByteCount(Store.Serialize(_state));
        return $"保存ファイル概算: {bytes / 1024.0:0.0} KiB\nアプリリンク: {_state.Apps.Count} / メモ: {_state.Memos.Count} / Todo日付: {_state.Todos.Count} / 予定: {_state.Events.Count} / 掲示板: {_state.Board.Count}\nエラー記録: {_errorCount}件 / プロセス使用メモリ: {Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024} MiB\n自動外部通信: {(_state.AutoWeather ? "許可" : "手動のみ")} / 画面保護: {(_state.ScreenProtect ? "有効" : "無効")}";
    }

    private void BuildAssistantCard(FlowLayoutPanel flow)
    {
        var card = Card("✦ NEXUSAssistant+ LOCAL — ローカル操作アシスタント", 245);
        var input = TextEntry("例：メモ: アイデアを書く / Todo: 英単語を復習 / 予定 2026-11-06 14:00 打ち合わせ");
        var output = new Label { Text = "こんにちは！メモ・Todo・予定・検索・翻訳などを手伝います。入力内容は外部AIへ自動送信しません。", ForeColor = Color.LightSkyBlue, AutoSize = false };
        Place(card, input, 14, 45, 940, 34); Place(card, MakeButton("実行", () => output.Text = RunAssistantCommand(input.Text)), 965, 45, 85, 34);
        Place(card, output, 14, 92, 1145, 60);
        int x = 14; foreach (var item in new[] { ("🌤 天気", "天気"), ("📅 予定", "予定"), ("✅ Todo", "Todo"), ("📝 メモ", "メモ"), ("🌐 翻訳", "翻訳") }) { string q = item.Item2; Place(card, MakeButton(item.Item1, () => output.Text = RunAssistantCommand(q)), x, 165, 95, 32); x += 101; }
        Place(card, MakeButton("🤖 ChatGPTに相談", () => { OpenUrl("https://chatgpt.com/"); }), 530, 165, 145, 32); Place(card, MakeButton("✨ Gemini", () => OpenUrl("https://gemini.google.com/app")), 680, 165, 95, 32); Place(card, MakeButton("🔎 Web検索", () => SearchWeb(input.Text)), 780, 165, 105, 32);
        flow.Controls.Add(card);
    }
    private string RunAssistantCommand(string text)
    {
        string raw = text.Trim(); if (raw.Length == 0) return "やりたいことを入力してください。";
        if (raw.StartsWith("メモ:") || raw.StartsWith("メモ：")) { string body = raw[3..].Trim(); string title = "NEXUSAssistant+のメモ"; int p = body.IndexOf('|'); if (p > 0) { title = body[..p].Trim(); body = body[(p + 1)..].Trim(); } if (body.Length == 0) return "メモ本文を入力してください。"; _state.Memos.Add(new MemoItem { Title = title, Body = body }); SaveState(); RenderMemosSafe(); return "✅ メモを保存しました：" + title; }
        if (raw.StartsWith("Todo:") || raw.StartsWith("Todo：")) { string body = raw[5..].Trim(); if (body.Length == 0) return "追加するTodoを入力してください。"; _currentTodoDate = DateTime.Today.ToString("yyyy-MM-dd"); GetTodos().Add(new TodoItem { Text = body }); SaveState(); RenderTodosSafe(); return "✅ 今日のTodoへ追加しました：" + body; }
        if (raw.StartsWith("予定") || raw.StartsWith("イベント"))
        {
            string body = Regex.Replace(raw, @"^(予定|イベント)[:：]?\s*", ""); string date = DateTime.Today.ToString("yyyy-MM-dd"); string time = "09:00";
            var dm = Regex.Match(body, @"20\d{2}-\d{2}-\d{2}"); if (dm.Success) { date = dm.Value; body = body.Replace(dm.Value, " "); }
            var tm = Regex.Match(body, @"(?:[01]\d|2[0-3]):[0-5]\d"); if (tm.Success) { time = tm.Value; body = body.Replace(tm.Value, " "); }
            body = body.Trim(' ', ':', '：', '-', ','); if (!DateTime.TryParse(date + " " + time, out var dt) || body.Length == 0) return "例：予定 2026-11-06 14:00 打ち合わせ";
            _state.Events.Add(new PlanItem { Start = dt, Title = body }); SaveState(); RenderEventsSafe(); return "✅ 予定を追加しました：" + dt.ToString("yyyy/MM/dd HH:mm") + " " + body;
        }
        if (raw.Equals("天気", StringComparison.OrdinalIgnoreCase)) { _tabs.SelectedIndex = 1; return "天気欄を開きました。都道府県を選んで手動更新してください。"; }
        if (raw.StartsWith("検索:") || raw.StartsWith("検索：")) { string q = raw[3..].Trim(); SearchWeb(q); return "検索をブラウザーで開きました。"; }
        if (raw.StartsWith("翻訳:") || raw.StartsWith("翻訳：")) { string q = raw[3..].Trim(); if (q.Length == 0) return "翻訳する文章を入力してください。"; if (MessageBox.Show("入力文をGoogle翻訳へ送信しますか？", "外部送信の確認", MessageBoxButtons.YesNo) == DialogResult.Yes) OpenUrl("https://translate.google.com/?sl=auto&tl=en&text=" + Uri.EscapeDataString(q)); return "確認後、Google翻訳を開きました。"; }
        if (raw.Contains("ヘルプ") || raw.Equals("help", StringComparison.OrdinalIgnoreCase)) return "対応形式：メモ: 本文 / Todo: 内容 / 予定 YYYY-MM-DD HH:mm 予定名 / 検索: キーワード / 翻訳: 文章。その他の質問は外部AIへ手動で引き継げます。";
        return "ローカル操作として解釈できませんでした。helpと入力して例を確認するか、外部AIを開いてください。";
    }
    private void RenderMemosSafe() { if (_memoList.IsHandleCreated) RenderMemos(); }
    private void RenderTodosSafe() { if (_todoList.IsHandleCreated) RenderTodos(); }
    private void RenderEventsSafe() { if (_eventList.IsHandleCreated) RenderEvents(); }

    private void OpenCommandPalette()
    {
        string q = Prompt("NEXUS COMMAND PALETTE", "機能名・キーワードを入力してください。\n例：Todo、メモ、CodeBridge、URLチェッカー、設定", "");
        if (q == null) return; q = q.Trim().ToLowerInvariant(); if (q.Length == 0) return;
        if (q.Contains("todo") || q.Contains("タスク")) _tabs.SelectedIndex = 1;
        else if (q.Contains("メモ") || q.Contains("memo")) _tabs.SelectedIndex = 1;
        else if (q.Contains("掲示板")) _tabs.SelectedIndex = 2;
        else if (q.Contains("絵") || q.Contains("draw")) _tabs.SelectedIndex = 3;
        else if (q.Contains("code") || q.Contains("プログラム")) _tabs.SelectedIndex = 5;
        else if (q.Contains("url") || q.Contains("security") || q.Contains("セキュリティ")) _tabs.SelectedIndex = 6;
        else if (q.Contains("設定") || q.Contains("backup")) _tabs.SelectedIndex = 7;
        else if (q.Contains("開発者") || q.Contains("developer")) _tabs.SelectedIndex = 8;
        else if (q.Contains("天気") || q.Contains("翻訳") || q.Contains("予定")) _tabs.SelectedIndex = 1;
        else if (q.Contains("ニュース")) OpenUrl("https://news.google.com/");
        else SearchWeb(q);
    }

    private void CheckSleepRestriction()
    {
        if (!_state.SleepEnabled || DateTime.Now < _sleepBypassUntil) { HideSleepOrPrivacyOverlay(true); return; }
        if (!TimeSpan.TryParse(_state.SleepStart, out var start) || !TimeSpan.TryParse(_state.SleepEnd, out var end) || start == end) return;
        TimeSpan now = DateTime.Now.TimeOfDay; bool active = start < end ? now >= start && now < end : now >= start || now < end;
        if (active) ShowSleepOverlay(false); else HideSleepOrPrivacyOverlay(true);
    }
    private void ShowSleepOverlay(bool preview)
    {
        if (_sleepOverlay != null && !_sleepOverlay.IsDisposed) { _sleepOverlay.Show(); _sleepOverlay.BringToFront(); return; }
        var overlay = new Form { Text = "NEXUS おやすみ制限", FormBorderStyle = FormBorderStyle.None, WindowState = FormWindowState.Maximized, TopMost = true, BackColor = Color.FromArgb(7, 13, 29), StartPosition = FormStartPosition.CenterScreen };
        var panel = new Panel { Size = new Size(560, 280), BackColor = Color.FromArgb(18, 32, 57) }; panel.Location = new Point((Screen.PrimaryScreen!.Bounds.Width - panel.Width) / 2, (Screen.PrimaryScreen.Bounds.Height - panel.Height) / 2); overlay.Controls.Add(panel);
        var title = new Label { Text = preview ? "☾ おやすみ制限（テスト中）" : "☾ おやすみ制限中", ForeColor = Color.FromArgb(190, 220, 255), Font = new Font("Yu Gothic UI", 22, FontStyle.Bold), AutoSize = true, Location = new Point(55, 35) }; panel.Controls.Add(title);
        var msg = new Label { Text = preview ? "休憩画面のテスト中です。1分後に終了します。" : $"設定したおやすみ時間です。\n{_state.SleepStart}〜{_state.SleepEnd}\n画面から離れて、目と体を休めましょう。", ForeColor = Color.White, AutoSize = false, Size = new Size(460, 80), Location = new Point(50, 100), TextAlign = ContentAlignment.MiddleCenter }; panel.Controls.Add(msg);
        var leave = new Button { Text = preview ? "閉じる" : "5分だけ一時解除", Location = new Point(170, 205), Size = new Size(210, 38) }; leave.Click += (_, _) => { _sleepBypassUntil = DateTime.Now.AddMinutes(preview ? 1 : 5); overlay.Close(); _sleepOverlay = null; };
        panel.Controls.Add(leave); overlay.FormClosed += (_, _) => { if (ReferenceEquals(_sleepOverlay, overlay)) _sleepOverlay = null; };
        _sleepOverlay = overlay; overlay.Show(this);
        if (preview) { var t = new System.Windows.Forms.Timer { Interval = 60000 }; t.Tick += (_, _) => { t.Stop(); if (!overlay.IsDisposed) overlay.Close(); }; t.Start(); }
    }
    private void ShowPrivacyOverlay()
    {
        if (_state.AnonCommunication) { SetStatus("通信匿名モードが有効です。外部サイトの起動はブロックされます。"); }
        HideSleepOrPrivacyOverlay(false);
        var form = new Form { Text = "NEXUS 画面保護", FormBorderStyle = FormBorderStyle.None, WindowState = FormWindowState.Maximized, TopMost = true, BackColor = Color.FromArgb(2, 7, 20) };
        var label = new Label { Text = "🔒 画面保護中\n画面の内容を一時的に隠しています。\n周囲の安全を確認してから再表示してください。", Dock = DockStyle.Fill, ForeColor = Color.FromArgb(190, 230, 255), TextAlign = ContentAlignment.MiddleCenter, Font = new Font("Yu Gothic UI", 22) };
        var resume = new Button { Text = "画面の表示を再開", Dock = DockStyle.Bottom, Height = 55 }; resume.Click += (_, _) => form.Close(); form.Controls.Add(label); form.Controls.Add(resume); form.Show(this);
        _privacyForm = form;
    }
    private Form? _privacyForm;
    private void HideSleepOrPrivacyOverlay(bool sleepOnly)
    {
        if (_sleepOverlay != null && !_sleepOverlay.IsDisposed) { var f = _sleepOverlay; _sleepOverlay = null; f.Close(); }
        if (!sleepOnly && _privacyForm != null && !_privacyForm.IsDisposed) { var f = _privacyForm; _privacyForm = null; f.Close(); }
    }

    private static string? Prompt(string title, string message, string initial)
    {
        using var form = new Form { Text = title, Size = new Size(520, 210), StartPosition = FormStartPosition.CenterParent, BackColor = Color.FromArgb(8, 16, 34), ForeColor = Color.White, FormBorderStyle = FormBorderStyle.FixedDialog, MaximizeBox = false, MinimizeBox = false };
        var lab = new Label { Text = message, Location = new Point(16, 15), Size = new Size(470, 60), ForeColor = Color.White };
        var box = new TextBox { Text = initial, Location = new Point(16, 85), Size = new Size(470, 28), BackColor = Color.FromArgb(3, 9, 23), ForeColor = Color.White };
        var ok = new Button { Text = "実行", DialogResult = DialogResult.OK, Location = new Point(300, 130), Size = new Size(85, 30) };
        var cancel = new Button { Text = "キャンセル", DialogResult = DialogResult.Cancel, Location = new Point(395, 130), Size = new Size(90, 30) };
        form.Controls.AddRange(new Control[] { lab, box, ok, cancel }); form.AcceptButton = ok; form.CancelButton = cancel;
        return form.ShowDialog() == DialogResult.OK ? box.Text : null;
    }
#endregion


    private void BuildNetworkAndCalculator(FlowLayoutPanel flow)
    {
        var speed = Card("📶 ネットワーク速度テスト（手動）", 135);
        var result = new Label { Text = "「測定」を押すとCloudflareから約5MBをダウンロードして下り速度の目安を測定します。", ForeColor = Color.LightSkyBlue, AutoSize = false };
        Place(speed, MakeButton("⚡ 速度を実測", async () =>
        {
            if (_state.AnonCommunication) { result.Text = "通信匿名モードが有効なため測定できません。"; return; }
            result.Text = "測定中…";
            try { var sw = Stopwatch.StartNew(); string url = "https://speed.cloudflare.com/__down?bytes=5000000&nexus=" + Guid.NewGuid().ToString("N"); byte[] bytes = await Http.GetByteArrayAsync(url); sw.Stop(); double mbps = bytes.Length * 8.0 / Math.Max(0.001, sw.Elapsed.TotalSeconds) / 1_000_000; result.Text = $"受信 {bytes.Length / 1024.0 / 1024.0:0.00} MiB / {sw.Elapsed.TotalSeconds:0.00}秒 / 下り目安 {mbps:0.00} Mbps（通信環境・サーバー負荷で変動します）"; }
            catch (Exception ex) { result.Text = "測定に失敗しました: " + ex.Message; _errorCount++; }
        }), 14, 45, 140, 33);
        Place(speed, result, 165, 48, 995, 52); flow.Controls.Add(speed);

        var calc = Card("🧮 電卓", 125);
        var expression = TextEntry("例： (125 + 75) * 1.1"); var answer = new Label { Text = "結果：—", ForeColor = Accent, Font = new Font("Yu Gothic UI", 13, FontStyle.Bold), AutoSize = true };
        Place(calc, expression, 14, 46, 550, 32); Place(calc, MakeButton("= 計算", () =>
        {
            string x = expression.Text.Trim(); if (x.Length == 0 || !Regex.IsMatch(x, @"^[0-9+\-*/().,%\s]+$")) { answer.Text = "数字と四則演算子・括弧のみ利用できます。"; return; }
            try { x = x.Replace("%", "/100"); object value = new DataTable().Compute(x, ""); answer.Text = "結果：" + Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture); }
            catch { answer.Text = "式を確認してください。"; }
        }), 575, 46, 100, 32); Place(calc, answer, 690, 48, 450, 32); flow.Controls.Add(calc);
    }

    private Control BuildGamesPage()
    {
        var flow = PageFlow(); var card = Card("🎮 NEXUS MINI GAMES", 690);
        var mode = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 180, BackColor = Color.FromArgb(7, 13, 30), ForeColor = Color.White };
        mode.Items.AddRange(new object[] { "🚗 ドライブ", "🐍 スネーク", "🎯 ターゲット" }); mode.SelectedIndex = 0;
        Place(card, mode, 14, 42, 180, 32);
        Place(card, MakeButton("▶ スタート／再開", () => _game?.Start(mode.SelectedIndex)), 205, 42, 150, 32);
        Place(card, MakeButton("◀ 左", () => _game?.Move(-1)), 365, 42, 70, 32);
        Place(card, MakeButton("右 ▶", () => _game?.Move(1)), 440, 42, 70, 32);
        Place(card, MakeButton("🔥 ターボ", () => _game?.Turbo()), 515, 42, 100, 32);
        Place(card, MakeButton("✕ リセット", () => _game?.Start(mode.SelectedIndex)), 620, 42, 105, 32);
        _game = new MiniGameSurface { Location = new Point(14, 88), Size = new Size(640, 480) }; card.Controls.Add(_game);
        var rules = new Label { Text = "ドライブ：左右キー／A・Dで車線移動、Spaceでターボ。障害物を避け、コインを取ります。\nスネーク：矢印キー／W・A・S・Dで移動し、赤い餌を集めます。壁や自分にぶつかると終了。\nターゲット：縮小する円をクリックして得点。制限時間内に多く命中させてください。\nEnterで再スタート、Escでゲームを停止します。", ForeColor = Color.Gainsboro, AutoSize = false, Location = new Point(680, 95), Size = new Size(480, 170) };
        card.Controls.Add(rules);
        var score = new Label { Text = "スコア：0", ForeColor = Accent, Font = new Font("Yu Gothic UI", 14, FontStyle.Bold), AutoSize = true, Location = new Point(680, 285) }; card.Controls.Add(score);
        _game.ScoreChanged += v => score.Text = "スコア：" + v;
        _game.SetMode(0);
        flow.Controls.Add(card); return flow;
    }

#region General utilities
    private void SearchWeb(string query)
    {
        string q = query.Trim(); if (q.Length == 0) return;
        if (Uri.TryCreate(q, UriKind.Absolute, out var uri) && (uri.Scheme == "http" || uri.Scheme == "https")) { OpenUrl(uri.ToString()); return; }
        OpenUrl("https://www.google.com/search?q=" + Uri.EscapeDataString(q));
    }
    private void OpenUrl(string url)
    {
        if (_state.AnonCommunication) { MessageBox.Show("通信匿名モードが有効です。外部サイトの起動をブロックしました。\n設定タブから解除できます。"); return; }
        if (!NormalizeUrl(url, out string safe)) { MessageBox.Show("URLの形式を確認してください。"); return; }
        try { Process.Start(new ProcessStartInfo(safe) { UseShellExecute = true }); } catch (Exception ex) { MessageBox.Show("ブラウザーを起動できません: " + ex.Message); }
    }
    private static bool NormalizeUrl(string input, out string normalized)
    {
        normalized = ""; if (string.IsNullOrWhiteSpace(input)) return false;
        string s = input.Trim(); if (!s.Contains("://")) s = "https://" + s;
        if (!Uri.TryCreate(s, UriKind.Absolute, out var uri)) return false;
        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps) return false;
        if (string.IsNullOrWhiteSpace(uri.Host)) return false;
        normalized = uri.ToString(); return true;
    }
    private static void SaveTextFile(string text, string fileName, string filter)
    {
        if (string.IsNullOrEmpty(text)) { MessageBox.Show("保存する内容がありません。"); return; }
        using var d = new SaveFileDialog { Filter = filter, FileName = fileName };
        if (d.ShowDialog() == DialogResult.OK) File.WriteAllText(d.FileName, text, new UTF8Encoding(false));
    }
    private static void TryDelete(string path) { try { if (File.Exists(path)) File.Delete(path); } catch { } }
#endregion
}


/// <summary>Simple native analog clock used alongside the digital clock.</summary>
internal sealed class AnalogClockControl : Control
{
    public Color Accent { get; set; } = Color.DeepSkyBlue;
    public AnalogClockControl() { DoubleBuffered = true; BackColor = Color.Transparent; }
    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        Graphics g = e.Graphics; g.SmoothingMode = SmoothingMode.AntiAlias;
        float size = Math.Min(ClientSize.Width, ClientSize.Height) - 8; float x = (ClientSize.Width - size) / 2f, y = (ClientSize.Height - size) / 2f;
        var bounds = new RectangleF(x, y, size, size);
        using var face = new SolidBrush(Color.FromArgb(185, 5, 18, 42)); using var rim = new Pen(Color.FromArgb(160, Accent), 2.2f); g.FillEllipse(face, bounds); g.DrawEllipse(rim, bounds);
        float cx = bounds.Left + size / 2f, cy = bounds.Top + size / 2f, r = size * .43f;
        using var ticks = new Pen(Color.FromArgb(190, 210, 235, 255), 1.2f); using var major = new Pen(Accent, 2.2f);
        for (int i = 0; i < 60; i++) { double a = i * Math.PI / 30; float inner = r * (i % 5 == 0 ? .84f : .92f); float ox = (float)Math.Sin(a), oy = (float)-Math.Cos(a); g.DrawLine(i % 5 == 0 ? major : ticks, cx + ox * inner, cy + oy * inner, cx + ox * r, cy + oy * r); }
        DateTime n = DateTime.Now; DrawHand(g, cx, cy, r * .48f, (n.Hour % 12 + n.Minute / 60f) * Math.PI / 6, 4.2f, Color.White);
        DrawHand(g, cx, cy, r * .72f, (n.Minute + n.Second / 60f) * Math.PI / 30, 2.8f, Color.FromArgb(225, 240, 255));
        DrawHand(g, cx, cy, r * .82f, n.Second * Math.PI / 30, 1.2f, Accent);
        using var hub = new SolidBrush(Accent); g.FillEllipse(hub, cx - 3.4f, cy - 3.4f, 6.8f, 6.8f);
    }
    private static void DrawHand(Graphics g, float cx, float cy, float length, double angle, float width, Color color)
    {
        using var pen = new Pen(color, width) { StartCap = LineCap.Round, EndCap = LineCap.Round };
        g.DrawLine(pen, cx, cy, cx + (float)Math.Sin(angle) * length, cy - (float)Math.Cos(angle) * length);
    }
}

/// <summary>Native Windows Forms mini-game surface for drive, snake and target modes.</summary>
internal sealed class MiniGameSurface : Panel
{
    private readonly System.Windows.Forms.Timer _timer = new() { Interval = 50 };
    private readonly Random _random = new();
    private readonly List<(int Lane, float Y)> _obstacles = new();
    private readonly List<Point> _snake = new();
    private Point _food = new(4, 5);
    private PointF _target = new(160, 220);
    private float _targetRadius = 34;
    private int _mode, _score, _lane = 1, _elapsed, _snakeStep;
    private Point _snakeDirection = new(1, 0), _nextSnakeDirection = new(1, 0);
    private bool _running, _over, _turbo;
    private float _speed = 4;
    private int _turboTicks;
    public event Action<int>? ScoreChanged;

    public MiniGameSurface()
    {
        DoubleBuffered = true; BackColor = Color.FromArgb(5, 10, 24); BorderStyle = BorderStyle.FixedSingle; TabStop = true;
        _timer.Tick += (_, _) => TickGame(); MouseDown += (_, e) => { if (_mode == 2) HitTarget(ToGamePoint(e.Location)); else if (_over) Start(_mode); Focus(); };
        SetStyle(ControlStyles.Selectable, true);
    }
    public void SetMode(int mode) { _mode = Math.Clamp(mode, 0, 2); Start(_mode); }
    public void Start(int mode)
    {
        _mode = Math.Clamp(mode, 0, 2); _score = 0; _elapsed = 0; _over = false; _running = true; _turbo = false; _turboTicks = 0; _obstacles.Clear(); _lane = 1; _speed = 4;
        _snake.Clear(); _snake.AddRange(new[] { new Point(8, 12), new Point(7, 12), new Point(6, 12) }); _snakeDirection = _nextSnakeDirection = new Point(1, 0); _snakeStep = 0; SpawnFood(); NewTarget();
        ScoreChanged?.Invoke(_score); _timer.Start(); Invalidate(); Focus();
    }
    public void Move(int direction)
    {
        if (!_running && !_over) Start(_mode);
        if (_mode == 0) _lane = Math.Clamp(_lane + Math.Sign(direction), 0, 2);
        else if (_mode == 1 && direction != 0)
        {
            Point d = direction < 0 ? new Point(-1, 0) : new Point(1, 0);
            if (!(d.X == -_snakeDirection.X && d.Y == -_snakeDirection.Y)) _nextSnakeDirection = d;
        }
        Invalidate();
    }
    public void Turbo() { if (_mode == 0 && _running) { _turbo = true; _turboTicks = 24; } }
    public void HandleKey(Keys key)
    {
        if (key == Keys.Escape) { _running = false; _timer.Stop(); Invalidate(); return; }
        if (key == Keys.Enter && _over) { Start(_mode); return; }
        if (_mode == 0) { if (key is Keys.Left or Keys.A) Move(-1); if (key is Keys.Right or Keys.D) Move(1); if (key == Keys.Space) Turbo(); }
        else if (_mode == 1)
        {
            Point d = key switch { Keys.Left or Keys.A => new Point(-1, 0), Keys.Right or Keys.D => new Point(1, 0), Keys.Up or Keys.W => new Point(0, -1), Keys.Down or Keys.S => new Point(0, 1), _ => Point.Empty };
            if (d != Point.Empty && !(d.X == -_snakeDirection.X && d.Y == -_snakeDirection.Y)) _nextSnakeDirection = d;
        }
        Invalidate();
    }
    private void TickGame()
    {
        if (!_running) return;
        _elapsed++;
        if (_mode == 0) TickDrive(); else if (_mode == 1) TickSnake(); else TickTarget();
        if (_turboTicks > 0) { _turboTicks--; if (_turboTicks == 0) _turbo = false; }
        Invalidate();
    }
    private void TickDrive()
    {
        float speed = _turbo ? _speed * 2.1f : _speed; _speed = Math.Min(9, _speed + .002f);
        if (_elapsed % Math.Max(8, (int)(30 / (speed / 4))) == 0) _obstacles.Add((_random.Next(3), -40));
        for (int i = 0; i < _obstacles.Count; i++) _obstacles[i] = (_obstacles[i].Lane, _obstacles[i].Y + speed);
        if (_obstacles.Any(o => o.Lane == _lane && o.Y > 380 && o.Y < 470)) EndGame();
        int before = _obstacles.Count; _obstacles.RemoveAll(o => o.Y > 500); _score += before - _obstacles.Count;
        if (_score % 5 == 0 && _score > 0) ScoreChanged?.Invoke(_score);
        ScoreChanged?.Invoke(_score);
    }
    private void TickSnake()
    {
        if (++_snakeStep < 4) return; _snakeStep = 0;
        Point dir = _nextSnakeDirection; _snakeDirection = dir;
        Point head = _snake[0]; Point next = new(head.X + dir.X, head.Y + dir.Y);
        if (next.X < 0 || next.X >= 16 || next.Y < 0 || next.Y >= 24 || _snake.Contains(next)) { EndGame(); return; }
        _snake.Insert(0, next);
        if (next == _food) { _score++; SpawnFood(); ScoreChanged?.Invoke(_score); } else _snake.RemoveAt(_snake.Count - 1);
    }
    private void TickTarget()
    {
        if (_elapsed >= 600) { EndGame(); return; }
        _targetRadius = Math.Max(8, _targetRadius - .12f);
        if (_targetRadius <= 8) NewTarget();
    }
    private void SpawnFood() { _food = new Point(_random.Next(16), _random.Next(24)); while (_snake.Contains(_food)) _food = new Point(_random.Next(16), _random.Next(24)); }
    private void NewTarget() { _target = new PointF(40 + _random.Next(240), 60 + _random.Next(370)); _targetRadius = 34; }
    private Point ToGamePoint(Point p) => new((int)(p.X * 320f / Math.Max(1, ClientSize.Width)), (int)(p.Y * 480f / Math.Max(1, ClientSize.Height)));
    private void HitTarget(Point p) { if (!_running || _over) { Start(2); return; } if (Math.Sqrt(Math.Pow(p.X - _target.X, 2) + Math.Pow(p.Y - _target.Y, 2)) <= _targetRadius + 8) { _score++; ScoreChanged?.Invoke(_score); NewTarget(); } }
    private void EndGame() { _running = false; _over = true; _timer.Stop(); Invalidate(); }
    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e); e.Graphics.SmoothingMode = SmoothingMode.AntiAlias; e.Graphics.ScaleTransform(ClientSize.Width / 320f, ClientSize.Height / 480f);
        using var back = new SolidBrush(Color.FromArgb(6, 10, 25)); e.Graphics.FillRectangle(back, 0, 0, 320, 480);
        using var white = new SolidBrush(Color.White); using var cyan = new SolidBrush(Color.FromArgb(60, 215, 255)); using var red = new SolidBrush(Color.FromArgb(255, 61, 110)); using var gold = new SolidBrush(Color.Gold); using var border = new Pen(Color.FromArgb(70, 175, 240), 3);
        if (_mode == 0)
        {
            using var road = new SolidBrush(Color.FromArgb(20, 28, 56)); e.Graphics.FillRectangle(road, 20, 0, 280, 480); e.Graphics.DrawRectangle(border, 20, 0, 280, 480);
            using var dash = new Pen(Color.FromArgb(130, 230, 240, 255), 2) { DashPattern = new float[] { 12, 12 } }; e.Graphics.DrawLine(dash, 113, 0, 113, 480); e.Graphics.DrawLine(dash, 207, 0, 207, 480);
            foreach (var o in _obstacles) DrawCar(e.Graphics, 66 + o.Lane * 94, o.Y, red);
            DrawCar(e.Graphics, 66 + _lane * 94, 400, cyan);
            e.Graphics.DrawString($"DRIVE  SCORE {_score}  SPEED {(int)(_speed * 20)}", Font, white, 30, 18);
        }
        else if (_mode == 1)
        {
            for (int x = 0; x < 16; x++) for (int y = 0; y < 24; y++) { using var pen = new Pen(Color.FromArgb(25, 90, 130, 170)); e.Graphics.DrawRectangle(pen, x * 20, y * 20, 20, 20); }
            e.Graphics.FillRectangle(red, _food.X * 20 + 3, _food.Y * 20 + 3, 14, 14);
            foreach (var p in _snake) e.Graphics.FillRectangle(cyan, p.X * 20 + 1, p.Y * 20 + 1, 18, 18);
            e.Graphics.DrawString($"SNAKE  SCORE {_score}", Font, white, 8, 5);
        }
        else
        {
            using var targetPen = new Pen(Color.FromArgb(72, 220, 255), 4); targetPen.Width = 4; e.Graphics.DrawEllipse(targetPen, _target.X - _targetRadius, _target.Y - _targetRadius, _targetRadius * 2, _targetRadius * 2);
            e.Graphics.DrawString($"TARGET  HIT {_score}  TIME {Math.Max(0, 10 - _elapsed / 60)}s", Font, white, 8, 5);
        }
        if (_over) { using var overlay = new SolidBrush(Color.FromArgb(190, 0, 0, 0)); e.Graphics.FillRectangle(overlay, 20, 175, 280, 115); using var f = new Font("Yu Gothic UI", 18, FontStyle.Bold); e.Graphics.DrawString("GAME OVER", f, white, 82, 205); e.Graphics.DrawString("Enter またはタップで再スタート", Font, white, 47, 247); }
        else if (!_running) e.Graphics.DrawString("停止中 — スタートで再開", Font, white, 75, 220);
    }
    private static void DrawCar(Graphics g, float x, float y, Brush brush)
    {
        g.FillRoundedRectangleCompat(brush, x - 16, y - 22, 32, 44, 6);
        using var glass = new SolidBrush(Color.FromArgb(120, 210, 245)); g.FillRectangle(glass, x - 10, y - 13, 20, 10);
    }
}

internal static class GraphicsExtensions
{
    public static void FillRoundedRectangleCompat(this Graphics graphics, Brush brush, float x, float y, float width, float height, float radius)
    {
        using var path = new GraphicsPath(); float d = radius * 2;
        path.AddArc(x, y, d, d, 180, 90); path.AddArc(x + width - d, y, d, d, 270, 90); path.AddArc(x + width - d, y + height - d, d, d, 0, 90); path.AddArc(x, y + height - d, d, d, 90, 90); path.CloseFigure(); graphics.FillPath(brush, path);
    }
}
