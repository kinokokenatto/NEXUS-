#include <QApplication>
#include <QMainWindow>
#include <QWidget>
#include <QFrame>
#include <QLabel>
#include <QPushButton>
#include <QToolButton>
#include <QLineEdit>
#include <QTextEdit>
#include <QPlainTextEdit>
#include <QComboBox>
#include <QCheckBox>
#include <QSlider>
#include <QSpinBox>
#include <QDoubleSpinBox>
#include <QDateEdit>
#include <QTimeEdit>
#include <QCalendarWidget>
#include <QListWidget>
#include <QListWidgetItem>
#include <QStackedWidget>
#include <QScrollArea>
#include <QSplitter>
#include <QStatusBar>
#include <QMenuBar>
#include <QFileDialog>
#include <QMessageBox>
#include <QInputDialog>
#include <QDialog>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QGroupBox>
#include <QProgressBar>
#include <QTableWidget>
#include <QHeaderView>
#include <QClipboard>
#include <QMimeData>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QPainter>
#include <QPainterPath>
#include <QRadialGradient>
#include <QSizePolicy>
#include <QPolygonF>
#include <QEvent>
#include <QResizeEvent>
#include <QMouseEvent>
#include <QKeyEvent>
#include <QCloseEvent>
#include <QTimer>
#include <QElapsedTimer>
#include <QDateTime>
#include <QDate>
#include <QTime>
#include <QUrl>
#include <QDesktopServices>
#include <QFile>
#include <QDir>
#include <QSaveFile>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QJsonParseError>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QBuffer>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QHash>
#include <QHostInfo>
#include <QSysInfo>
#include <QScreen>
#include <QOperatingSystemVersion>
#include <QTextStream>
#include <QTemporaryFile>
#include <QCryptographicHash>
#include <QUrlQuery>
#include <QLineF>
#include <QStorageInfo>
#include <QThread>
#include <QVariant>
#include <QByteArray>
#include <QColor>
#include <QColorDialog>
#include <QSignalBlocker>
#include <QUuid>
#include <QLocale>
#include <QFontDatabase>
#include <QFileInfo>
#include <QDateTime>
#include <QPointer>
#include <QStyle>
#include <QStyleFactory>
#include <QGraphicsDropShadowEffect>
#include <QMetaObject>

#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/err.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <numbers>
#include <cstdint>
#include <functional>
#include <limits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {

constexpr auto kAppName = "NEXUS SUPER4.1";
constexpr auto kDataFile = "nexus_super41.json";
constexpr int kAudioRate = 44100;

struct Prefecture {
    QString name;
    double lat;
    double lon;
    QString city;
};

const QVector<Prefecture>& prefectures() {
    static const QVector<Prefecture> items = {
        {QStringLiteral("北海道"),43.0642,141.3469,QStringLiteral("札幌市")},
        {QStringLiteral("青森県"),40.8244,140.7400,QStringLiteral("青森市")},
        {QStringLiteral("岩手県"),39.7036,141.1527,QStringLiteral("盛岡市")},
        {QStringLiteral("宮城県"),38.2682,140.8694,QStringLiteral("仙台市")},
        {QStringLiteral("秋田県"),39.7186,140.1024,QStringLiteral("秋田市")},
        {QStringLiteral("山形県"),38.2404,140.3633,QStringLiteral("山形市")},
        {QStringLiteral("福島県"),37.7503,140.4676,QStringLiteral("福島市")},
        {QStringLiteral("茨城県"),36.3418,140.4468,QStringLiteral("水戸市")},
        {QStringLiteral("栃木県"),36.5657,139.8836,QStringLiteral("宇都宮市")},
        {QStringLiteral("群馬県"),36.3907,139.0604,QStringLiteral("前橋市")},
        {QStringLiteral("埼玉県"),35.8617,139.6455,QStringLiteral("さいたま市")},
        {QStringLiteral("千葉県"),35.6073,140.1063,QStringLiteral("千葉市")},
        {QStringLiteral("東京都"),35.6895,139.6917,QStringLiteral("新宿区")},
        {QStringLiteral("神奈川県"),35.4478,139.6425,QStringLiteral("横浜市")},
        {QStringLiteral("新潟県"),37.9026,139.0236,QStringLiteral("新潟市")},
        {QStringLiteral("富山県"),36.6953,137.2113,QStringLiteral("富山市")},
        {QStringLiteral("石川県"),36.5944,136.6256,QStringLiteral("金沢市")},
        {QStringLiteral("福井県"),36.0652,136.2216,QStringLiteral("福井市")},
        {QStringLiteral("山梨県"),35.6642,138.5684,QStringLiteral("甲府市")},
        {QStringLiteral("長野県"),36.6513,138.1810,QStringLiteral("長野市")},
        {QStringLiteral("岐阜県"),35.3912,136.7223,QStringLiteral("岐阜市")},
        {QStringLiteral("静岡県"),34.9769,138.3831,QStringLiteral("静岡市")},
        {QStringLiteral("愛知県"),35.1802,136.9066,QStringLiteral("名古屋市")},
        {QStringLiteral("三重県"),34.7303,136.5086,QStringLiteral("津市")},
        {QStringLiteral("滋賀県"),35.0179,135.8546,QStringLiteral("大津市")},
        {QStringLiteral("京都府"),35.0116,135.7681,QStringLiteral("京都市")},
        {QStringLiteral("大阪府"),34.6863,135.5200,QStringLiteral("大阪市")},
        {QStringLiteral("兵庫県"),34.6913,135.1830,QStringLiteral("神戸市")},
        {QStringLiteral("奈良県"),34.6851,135.8329,QStringLiteral("奈良市")},
        {QStringLiteral("和歌山県"),34.2260,135.1675,QStringLiteral("和歌山市")},
        {QStringLiteral("鳥取県"),35.5039,134.2377,QStringLiteral("鳥取市")},
        {QStringLiteral("島根県"),35.4723,133.0505,QStringLiteral("松江市")},
        {QStringLiteral("岡山県"),34.6618,133.9344,QStringLiteral("岡山市")},
        {QStringLiteral("広島県"),34.3963,132.4596,QStringLiteral("広島市")},
        {QStringLiteral("山口県"),34.1861,131.4705,QStringLiteral("山口市")},
        {QStringLiteral("徳島県"),34.0658,134.5593,QStringLiteral("徳島市")},
        {QStringLiteral("香川県"),34.3401,134.0434,QStringLiteral("高松市")},
        {QStringLiteral("愛媛県"),33.8416,132.7657,QStringLiteral("松山市")},
        {QStringLiteral("高知県"),33.5597,133.5311,QStringLiteral("高知市")},
        {QStringLiteral("福岡県"),33.6064,130.4183,QStringLiteral("福岡市")},
        {QStringLiteral("佐賀県"),33.2494,130.2988,QStringLiteral("佐賀市")},
        {QStringLiteral("長崎県"),32.7448,129.8737,QStringLiteral("長崎市")},
        {QStringLiteral("熊本県"),32.7898,130.7417,QStringLiteral("熊本市")},
        {QStringLiteral("大分県"),33.2382,131.6126,QStringLiteral("大分市")},
        {QStringLiteral("宮崎県"),31.9111,131.4239,QStringLiteral("宮崎市")},
        {QStringLiteral("鹿児島県"),31.5602,130.5581,QStringLiteral("鹿児島市")},
        {QStringLiteral("沖縄県"),26.2124,127.6809,QStringLiteral("那覇市")}
    };
    return items;
}

QString weatherDescription(int code) {
    switch (code) {
    case 0: return QStringLiteral("快晴 ☀️");
    case 1: return QStringLiteral("晴れ 🌤️");
    case 2: return QStringLiteral("一部曇り ⛅");
    case 3: return QStringLiteral("曇り ☁️");
    case 45: case 48: return QStringLiteral("霧 🌫️");
    case 51: case 53: case 55: return QStringLiteral("霧雨 🌦️");
    case 56: case 57: case 66: case 67: return QStringLiteral("着氷性の雨 🌧️");
    case 61: return QStringLiteral("小雨 🌧️");
    case 63: return QStringLiteral("雨 🌧️");
    case 65: return QStringLiteral("大雨 🌧️");
    case 71: case 73: case 77: case 85: return QStringLiteral("雪 🌨️");
    case 75: case 86: return QStringLiteral("大雪 ❄️");
    case 80: case 81: case 82: return QStringLiteral("にわか雨 🌦️");
    case 95: case 96: case 99: return QStringLiteral("雷雨 ⛈️");
    default: return QStringLiteral("天気情報あり");
    }
}

QString appDataPath() {
    QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir + QDir::separator() + QString::fromLatin1(kDataFile);
}

QFrame* makeCard(const QString& title, QVBoxLayout* parentLayout, const QString& objectName = {}) {
    auto* frame = new QFrame;
    frame->setObjectName(objectName.isEmpty() ? QStringLiteral("nexusCard") : objectName);
    frame->setProperty("nexusCard", true);
    auto* layout = new QVBoxLayout(frame);
    layout->setContentsMargins(16, 14, 16, 14);
    layout->setSpacing(9);
    if (!title.isEmpty()) {
        auto* heading = new QLabel(title);
        heading->setObjectName(QStringLiteral("cardTitle"));
        layout->addWidget(heading);
    }
    parentLayout->addWidget(frame);
    return frame;
}

QLabel* makeHint(const QString& text, QWidget* parent = nullptr) {
    auto* label = new QLabel(text, parent);
    label->setObjectName(QStringLiteral("hint"));
    label->setWordWrap(true);
    return label;
}

QPushButton* makeButton(const QString& text, QWidget* parent = nullptr) {
    auto* button = new QPushButton(text, parent);
    button->setCursor(Qt::PointingHandCursor);
    return button;
}

QString encodeUrl(const QString& text) {
    return QString::fromLatin1(QUrl::toPercentEncoding(text));
}

QString bytesText(qint64 bytes) {
    if (bytes < 1024) return QStringLiteral("%1 B").arg(bytes);
    if (bytes < 1024 * 1024) return QStringLiteral("%1 KiB").arg(bytes / 1024.0, 0, 'f', 1);
    return QStringLiteral("%1 MiB").arg(bytes / (1024.0 * 1024.0), 0, 'f', 2);
}

QByteArray makeWav(const QVector<float>& samples) {
    QByteArray data;
    const quint32 dataSize = static_cast<quint32>(samples.size() * 2);
    auto append16 = [&data](quint16 v) { data.append(char(v & 0xff)); data.append(char((v >> 8) & 0xff)); };
    auto append32 = [&data](quint32 v) { data.append(char(v & 0xff)); data.append(char((v >> 8) & 0xff)); data.append(char((v >> 16) & 0xff)); data.append(char((v >> 24) & 0xff)); };
    data.append("RIFF", 4); append32(36 + dataSize); data.append("WAVEfmt ", 8);
    append32(16); append16(1); append16(1); append32(kAudioRate); append32(kAudioRate * 2); append16(2); append16(16);
    data.append("data", 4); append32(dataSize);
    for (float sample : samples) {
        const auto v = static_cast<qint16>(std::clamp(sample, -1.0f, 1.0f) * 32760.0f);
        append16(static_cast<quint16>(v));
    }
    return data;
}

QByteArray makeSynthTrack(int track, int seconds = 18) {
    const int count = kAudioRate * seconds;
    QVector<float> samples;
    samples.resize(count);
    static const std::array<std::array<double, 5>, 6> scales = {{
        {{220.0,261.63,329.63,392.0,440.0}}, {{174.61,220.0,261.63,349.23,392.0}},
        {{130.81,164.81,196.0,261.63,329.63}}, {{261.63,329.63,392.0,523.25,659.25}},
        {{146.83,196.0,220.0,293.66,392.0}}, {{196.0,246.94,293.66,369.99,440.0}}
    }};
    const auto& notes = scales[static_cast<size_t>(std::clamp(track, 0, 5))];
    const double bpm = 72.0 + track * 8.0;
    const double beat = 60.0 / bpm;
    for (int i = 0; i < count; ++i) {
        const double t = static_cast<double>(i) / kAudioRate;
        const int step = static_cast<int>(t / beat) % 5;
        const double f = notes[static_cast<size_t>(step)] * ((step % 2) ? 1.0 : 0.5);
        const double envelope = std::min(1.0, t / 1.5) * std::min(1.0, (seconds - t) / 2.0);
        const double wobble = 1.0 + 0.003 * std::sin(2.0 * std::numbers::pi * 0.23 * t);
        const double melody = std::sin(2.0 * std::numbers::pi * f * wobble * t) * 0.19;
        const double overtone = std::sin(2.0 * std::numbers::pi * f * 2.005 * t) * 0.045;
        const double bass = std::sin(2.0 * std::numbers::pi * notes[static_cast<size_t>((step + 3) % 5)] * 0.25 * t) * 0.11;
        const double pulse = (std::fmod(t, beat) < 0.05 ? 0.05 : 0.0);
        samples[i] = static_cast<float>((melody + overtone + bass + pulse) * envelope);
    }
    return makeWav(samples);
}

class AnalogClockWidget final : public QWidget {
public:
    explicit AnalogClockWidget(QWidget* parent = nullptr) : QWidget(parent) {
        setMinimumSize(76, 76);
        setMaximumSize(136, 136);
        setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
    }
    QSize sizeHint() const override { return {116, 116}; }
protected:
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing);
        const qreal side = std::min(width(), height());
        p.translate(width() / 2.0, height() / 2.0);
        p.scale(side / 120.0, side / 120.0);

        QRadialGradient face(0, 0, 59, -18, -23);
        face.setColorAt(0.0, QColor(19, 42, 75, 245));
        face.setColorAt(0.82, QColor(5, 14, 34, 245));
        face.setColorAt(1.0, QColor(2, 8, 22, 245));
        p.setPen(QPen(QColor(91, 218, 255, 190), 1.6));
        p.setBrush(face);
        p.drawEllipse(QPointF(0, 0), 57, 57);
        p.setPen(QPen(QColor(84, 189, 255, 75), 1.0));
        p.drawEllipse(QPointF(0, 0), 51, 51);

        for (int i = 0; i < 60; ++i) {
            p.save();
            p.rotate(i * 6.0);
            const bool major = (i % 5) == 0;
            p.setPen(QPen(major ? QColor(223, 246, 255, 230) : QColor(130, 192, 224, 125),
                          major ? 1.7 : 0.8));
            p.drawLine(QPointF(0, major ? -47 : -50), QPointF(0, -54));
            p.restore();
        }
        p.setPen(QColor(220, 242, 255, 235));
        QFont numerals(QStringLiteral("Sans Serif"), 7, QFont::DemiBold);
        p.setFont(numerals);
        for (int n = 1; n <= 12; ++n) {
            const double a = n * std::numbers::pi / 6.0;
            const QPointF pos(std::sin(a) * 38.0, -std::cos(a) * 38.0);
            QRectF r(pos.x() - 7, pos.y() - 5, 14, 10);
            p.drawText(r, Qt::AlignCenter, QString::number(n));
        }

        const QTime now = QTime::currentTime();
        const double second = now.second() + now.msec() / 1000.0;
        const double minute = now.minute() + second / 60.0;
        const double hour = (now.hour() % 12) + minute / 60.0;
        auto hand = [&p](double angle, double length, double width, QColor color, double tail) {
            p.save(); p.rotate(angle); p.setPen(QPen(color, width, Qt::SolidLine, Qt::RoundCap));
            p.drawLine(QPointF(0, tail), QPointF(0, -length)); p.restore();
        };
        hand(hour * 30.0, 27, 3.2, QColor(236, 247, 255), 5);
        hand(minute * 6.0, 39, 2.1, QColor(196, 237, 255), 7);
        hand(second * 6.0, 45, 1.0, QColor(73, 225, 255), 10);
        p.setPen(Qt::NoPen); p.setBrush(QColor(77, 224, 255)); p.drawEllipse(QPointF(0, 0), 3.0, 3.0);
    }
};

class SafeExpression {
public:
    explicit SafeExpression(QString input) : text_(std::move(input)) {}
    double evaluate() { pos_ = 0; const double v = expression(); skip(); if (pos_ != text_.size() || !std::isfinite(v)) throw std::runtime_error("invalid expression"); return v; }
private:
    QString text_; qsizetype pos_ = 0;
    void skip() { while (pos_ < text_.size() && text_[pos_].isSpace()) ++pos_; }
    bool eat(QChar c) { skip(); if (pos_ < text_.size() && text_[pos_] == c) { ++pos_; return true; } return false; }
    double expression() { double v = term(); while (true) { if (eat('+')) v += term(); else if (eat('-')) v -= term(); else break; } return v; }
    double term() { double v = power(); while (true) { if (eat('*')) v *= power(); else if (eat('/')) { double d = power(); if (d == 0) throw std::runtime_error("division by zero"); v /= d; } else if (eat('%')) { double d = power(); if (d == 0) throw std::runtime_error("division by zero"); v = std::fmod(v, d); } else break; } return v; }
    double power() { double v = unary(); if (eat('^')) v = std::pow(v, power()); return v; }
    double unary() { if (eat('+')) return unary(); if (eat('-')) return -unary(); return atom(); }
    double atom() {
        skip(); if (eat('(')) { double v = expression(); if (!eat(')')) throw std::runtime_error("missing )"); return v; }
        const qsizetype start = pos_;
        while (pos_ < text_.size() && (text_[pos_].isDigit() || text_[pos_] == '.' || text_[pos_].toLower() == 'e' || ((text_[pos_] == '+' || text_[pos_] == '-') && pos_ > start && (text_[pos_ - 1].toLower() == 'e')))) ++pos_;
        if (start == pos_) throw std::runtime_error("number expected");
        bool ok = false; double v = text_.mid(start, pos_ - start).toDouble(&ok); if (!ok) throw std::runtime_error("invalid number"); return v;
    }
};

class PaintCanvas final : public QWidget {
public:
    explicit PaintCanvas(QWidget* parent = nullptr) : QWidget(parent) {
        setMinimumSize(720, 420); setAttribute(Qt::WA_StaticContents); setMouseTracking(true);
        image_ = QImage(1200, 700, QImage::Format_ARGB32_Premultiplied); image_.fill(Qt::white); snapshot_ = image_;
    }
    void setTool(QString t) { tool_ = std::move(t); }
    void setPenColor(QColor c) { color_ = c; }
    void setWidth(int w) { width_ = std::clamp(w, 1, 60); }
    void setFill(bool f) { fill_ = f; }
    void insertText(const QString& text) { pendingText_ = text; }
    bool undo() { if (undo_.isEmpty()) return false; redo_.push_back(image_); image_ = undo_.takeLast(); update(); notifyChange(); return true; }
    bool redo() { if (redo_.isEmpty()) return false; undo_.push_back(image_); image_ = redo_.takeLast(); update(); notifyChange(); return true; }
    void clearCanvas() { pushUndo(); image_.fill(background_); update(); notifyChange(); }
    void setBackground(QColor c) { background_ = c; }
    bool savePng(const QString& path) { return image_.save(path, "PNG"); }
    void setChangeHandler(std::function<void(const QImage&)> handler) { changeHandler_ = std::move(handler); }
    void loadImage(const QImage& image) { if(!image.isNull()) { image_ = image.scaled(image_.size(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_ARGB32_Premultiplied); update(); } }
    void importImage(const QString& path) {
        QImage imported(path); if (imported.isNull()) return;
        pushUndo(); QPainter p(&image_); imported = imported.scaled(image_.size(), Qt::KeepAspectRatio, Qt::SmoothTransformation);
        p.drawImage((image_.width()-imported.width())/2, (image_.height()-imported.height())/2, imported); update(); notifyChange();
    }
protected:
    void paintEvent(QPaintEvent*) override {
        QPainter p(this); p.fillRect(rect(), QColor(6, 8, 18));
        p.setRenderHint(QPainter::SmoothPixmapTransform);
        QRectF target = rect(); target.setWidth(std::min(static_cast<double>(width()), height() * (1200.0/700.0)));
        target.moveLeft((width() - target.width()) / 2.0);
        p.drawImage(target, image_);
        if (drawing_ && (tool_ == "rect" || tool_ == "line" || tool_ == "ellipse")) {
            QPen pen(color_, width_); p.setPen(pen); p.setBrush(fill_ ? QBrush(color_) : Qt::NoBrush);
            QRectF r(start_, current_); if (tool_ == "line") p.drawLine(start_, current_); else if (tool_ == "ellipse") p.drawEllipse(r.normalized()); else p.drawRect(r.normalized());
        }
    }
    void mousePressEvent(QMouseEvent* e) override {
        if (e->button() != Qt::LeftButton) return;
        pushUndo(); drawing_ = true; start_ = toImage(e->position()); current_ = start_; last_ = start_;
        if (tool_ == "text" || tool_ == "stamp") {
            QPainter p(&image_); p.setPen(color_); QFont f = p.font(); f.setBold(true); f.setPointSize(20); p.setFont(f); p.drawText(start_, pendingText_.isEmpty() ? (tool_=="stamp"?QStringLiteral("⭐"):QStringLiteral("NEXUS")) : pendingText_); drawing_ = false; notifyChange();
        }
        update();
    }
    void mouseMoveEvent(QMouseEvent* e) override {
        if (!drawing_) return; current_ = toImage(e->position());
        if (tool_ == "pen" || tool_ == "marker" || tool_ == "neon" || tool_ == "rainbow" || tool_ == "eraser" || tool_ == "spray") {
            QPainter p(&image_); p.setRenderHint(QPainter::Antialiasing);
            QColor c = tool_ == "eraser" ? background_ : (tool_ == "rainbow" ? QColor::fromHsv((frameHue_+=17)%360,255,255) : color_);
            QPen pen(c, tool_ == "marker" ? width_ * 3 : (tool_ == "eraser" ? width_ * 2 : width_), Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
            if (tool_ == "marker") c.setAlpha(75), pen.setColor(c);
            if (tool_ == "neon") { pen.setWidth(width_ * 2); p.setPen(pen); p.drawLine(last_, current_); pen.setWidth(width_); p.setPen(pen); }
            else if (tool_ == "spray") { p.setPen(Qt::NoPen); p.setBrush(c); for (int i=0;i<30;++i) { const double a=QRandomGenerator::global()->generateDouble()*2*std::numbers::pi; const double r=QRandomGenerator::global()->generateDouble()*width_*3; p.drawEllipse(QPointF(current_.x()+std::cos(a)*r,current_.y()+std::sin(a)*r),1.2,1.2); } }
            else p.setPen(pen), p.drawLine(last_, current_);
            last_ = current_;
        }
        update();
    }
    void mouseReleaseEvent(QMouseEvent* e) override {
        if (!drawing_) return; current_ = toImage(e->position());
        if (tool_ == "line" || tool_ == "arrow" || tool_ == "rect" || tool_ == "ellipse" || tool_ == "triangle") {
            QPainter p(&image_); p.setRenderHint(QPainter::Antialiasing); p.setPen(QPen(color_, width_)); p.setBrush(fill_ ? QBrush(color_) : Qt::NoBrush);
            QRectF r(start_, current_); if (tool_ == "line") p.drawLine(start_, current_); else if (tool_ == "arrow") {p.drawLine(start_,current_);QLineF ln(start_,current_);QPointF a=ln.p2(),v=ln.p1()-ln.p2();double angle=std::atan2(v.y(),v.x());double head=18;p.drawLine(a,a+QPointF(std::cos(angle-.5)*head,std::sin(angle-.5)*head));p.drawLine(a,a+QPointF(std::cos(angle+.5)*head,std::sin(angle+.5)*head));} else if (tool_ == "ellipse") p.drawEllipse(r.normalized()); else if(tool_=="triangle"){QPolygonF poly;QRectF n=r.normalized();poly<<QPointF(n.center().x(),n.top())<<n.bottomRight()<<QPointF(n.left(),n.bottom());p.drawPolygon(poly);}else p.drawRect(r.normalized());
        }
        drawing_ = false; update(); notifyChange();
    }
private:
    std::function<void(const QImage&)> changeHandler_;
    void notifyChange() { if(changeHandler_) changeHandler_(image_); }
    QImage image_; QColor color_{42,107,255}; QColor background_{Qt::white}; QString tool_{QStringLiteral("pen")}; QString pendingText_;
    int width_ = 5; int frameHue_ = 0; bool fill_ = false; bool drawing_ = false; QPointF start_, current_, last_; QImage snapshot_; QVector<QImage> undo_, redo_;
    QPointF toImage(QPointF p) const {
        const double w = std::min(static_cast<double>(width()), height() * (1200.0/700.0)); const double left=(width()-w)/2.0; const double h=w*(700.0/1200.0);
        return QPointF(std::clamp((p.x()-left)/w*1200.0,0.0,1200.0), std::clamp(p.y()/h*700.0,0.0,700.0));
    }
    void pushUndo() { undo_.push_back(image_); if (undo_.size() > 16) undo_.removeFirst(); redo_.clear(); }
};

class MiniGameWidget final : public QWidget {
public:
    explicit MiniGameWidget(QWidget* parent=nullptr) : QWidget(parent) {
        setFixedSize(320,480); setFocusPolicy(Qt::StrongFocus);
        connect(&tick_,&QTimer::timeout,this,[this]{step();}); tick_.setInterval(16); reset(0);
    }
    void setMode(int mode){reset(std::clamp(mode,0,2));}
    void pause(){tick_.stop();}
    void setCloseHandler(std::function<void()> fn){closeRequested_=std::move(fn);}
    void moveLane(int d){if(mode_==0&&!over_)lane_=std::clamp(lane_+d,0,2);update();}
    void turbo(){if(mode_==0&&!over_&&turbo_<=0)turbo_=40;}
protected:
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);p.setRenderHint(QPainter::Antialiasing);p.fillRect(rect(),QColor(5,9,23));
        const QColor accent=QColor::fromHsv(hue_,220,255);
        if(mode_==0){
            p.fillRect(20,0,280,480,QColor(20,28,54));p.setPen(QPen(accent,3));p.drawRect(20,0,280,480);
            p.setPen(QPen(QColor(255,255,255,110),2,Qt::DashLine));p.drawLine(113,0,113,480);p.drawLine(207,0,207,480);
            for(const auto&o:obstacles_)drawCar(p, laneX(o.lane),o.y,QColor("#ff3d6e"));
            for(const auto&c:coins_){p.setBrush(QColor("#ffe14a"));p.setPen(Qt::NoPen);p.drawEllipse(QPointF(laneX(c.lane),c.y),8,8);}
            drawCar(p,playerX_,400,turbo_>0?QColor("#ffbd45"):accent);
            p.setPen(Qt::white);p.setFont(QFont(QStringLiteral("Sans Serif"),12,QFont::Bold));p.drawText(30,26,QStringLiteral("SCORE %1    %2 km/h").arg(score_).arg(static_cast<int>(speed_*20)));
            p.setPen(Qt::NoPen);p.setBrush(QColor(255,255,255,45));p.drawRoundedRect(30,458,100,8,4,4);p.setBrush(turbo_>0?QColor("#ffbd45"):accent);p.drawRoundedRect(30,458,turbo_,8,4,4);
        } else if(mode_==1){
            p.setPen(Qt::NoPen);p.setBrush(QColor("#ff3d6e"));p.drawEllipse(food_.x()*20+4,food_.y()*20+4,12,12);
            p.setBrush(QColor("#64708f"));for(const auto&b:blocks_)p.drawRect(b.x()*20+1,b.y()*20+1,18,18);
            for(int i=snake_.size()-1;i>=0;--i){QColor c=accent;c.setAlpha(std::max(45,255-i*9));p.setBrush(c);p.drawRoundedRect(snake_[i].x()*20+1,snake_[i].y()*20+1,18,18,4,4);}
            p.setPen(Qt::white);p.setFont(QFont(QStringLiteral("Sans Serif"),12,QFont::Bold));p.drawText(10,22,QStringLiteral("SCORE %1  COMBO ×%2").arg(score_).arg(combo_));
        } else {
            for(const auto&t:targets_){QColor c=t.bad?QColor("#ff3d6e"):accent;p.setPen(QPen(c,4));p.setBrush(Qt::NoBrush);p.drawEllipse(QPointF(t.x,t.y),t.r,t.r);p.setPen(QPen(c,2));p.drawLine(QPointF(t.x-t.r*.35,t.y-t.r*.35),QPointF(t.x+t.r*.35,t.y+t.r*.35));p.drawLine(QPointF(t.x+t.r*.35,t.y-t.r*.35),QPointF(t.x-t.r*.35,t.y+t.r*.35));}
            p.setPen(Qt::white);p.setFont(QFont(QStringLiteral("Sans Serif"),12,QFont::Bold));p.drawText(10,22,QStringLiteral("SCORE %1  COMBO ×%2").arg(score_).arg(combo_));p.setPen(QColor("#ff6b86"));p.drawText(250,22,QStringLiteral("♥ %1").arg(lives_));
        }
        if(over_){p.fillRect(20,170,280,120,QColor(0,0,0,190));p.setPen(Qt::white);p.setFont(QFont(QStringLiteral("Sans Serif"),23,QFont::Bold));p.drawText(QRect(20,180,280,45),Qt::AlignCenter,QStringLiteral("GAME OVER"));p.setFont(QFont(QStringLiteral("Sans Serif"),11));p.drawText(QRect(20,225,280,40),Qt::AlignCenter,QStringLiteral("Enter またはタップで再スタート"));}
    }
    void keyPressEvent(QKeyEvent*e) override {
        if(e->key()==Qt::Key_Escape){tick_.stop();emitCloseRequested_();return;}
        if(over_&&e->key()==Qt::Key_Return){reset(mode_);return;}
        if(mode_==0){if(e->key()==Qt::Key_Left||e->key()==Qt::Key_A)moveLane(-1);else if(e->key()==Qt::Key_Right||e->key()==Qt::Key_D)moveLane(1);else if(e->key()==Qt::Key_Space||e->key()==Qt::Key_Up)turbo();}
        else if(mode_==1){QPoint next=direction_;if(e->key()==Qt::Key_Left||e->key()==Qt::Key_A)next={-1,0};else if(e->key()==Qt::Key_Right||e->key()==Qt::Key_D)next={1,0};else if(e->key()==Qt::Key_Up||e->key()==Qt::Key_W)next={0,-1};else if(e->key()==Qt::Key_Down||e->key()==Qt::Key_S)next={0,1};if(next+direction_!=QPoint(0,0))direction_=next;}
        update();
    }
    void mousePressEvent(QMouseEvent*e) override {
        if(over_){reset(mode_);return;}if(mode_!=2)return;QPointF pos=e->position();for(int i=targets_.size()-1;i>=0;--i){auto t=targets_[i];if(QLineF(pos,QPointF(t.x,t.y)).length()<=t.r+12){targets_.removeAt(i);if(t.bad){--lives_;combo_=1;}else{score_+=10*combo_;combo_=std::min(combo_+1,10);}if(lives_<=0)finish();break;}}update();
    }
private:
    struct Obstacle{int lane;double y;double factor;};struct Target{double x,y,r;bool bad;};
    QTimer tick_;int mode_=0,lane_=1,score_=0,combo_=1,lives_=3,hue_=190,turbo_=0,frame_=0;double speed_=6,playerX_=160,targetClock_=0;bool over_=false;
    QVector<Obstacle> obstacles_;QVector<Obstacle> coins_;QVector<QPoint> snake_;QVector<QPoint> blocks_;QPoint direction_{1,0},food_{3,5};QVector<Target> targets_;
    std::function<void()> closeRequested_;
    void emitCloseRequested_(){if(closeRequested_)closeRequested_();}
    int laneX(int lane)const{return 66+lane*94;}
    void drawCar(QPainter&p,int x,int y,const QColor&c){p.setPen(Qt::NoPen);p.setBrush(c);p.drawRoundedRect(x-18,y-30,36,60,7,7);p.setBrush(QColor(0,0,0,130));p.drawRoundedRect(x-13,y-16,26,14,3,3);}
    void reset(int m){mode_=m;score_=0;combo_=1;lives_=3;over_=false;lane_=1;speed_=6;playerX_=160;turbo_=0;frame_=0;obstacles_.clear();coins_.clear();targets_.clear();snake_.clear();blocks_.clear();
        if(mode_==1){snake_={{8,12},{7,12},{6,12}};direction_={1,0};food_={3,5};}
        if(mode_==2){targetClock_=0;spawnTarget();}
        tick_.start();setFocus();update();
    }
    void finish(){over_=true;tick_.stop();update();}
    void spawnTarget(){targets_.append({40+QRandomGenerator::global()->bounded(240),60+QRandomGenerator::global()->bounded(360),36.0,QRandomGenerator::global()->bounded(5)==0});}
    void step(){if(over_)return;++frame_;
        if(mode_==0){if(turbo_>0)--turbo_;double v=speed_*(turbo_>0?1.75:1.0);speed_+=0.003;playerX_+=(laneX(lane_)-playerX_)*0.26;if(QRandomGenerator::global()->bounded(1000)<32&& (obstacles_.isEmpty()||obstacles_.last().y>125))obstacles_.append({QRandomGenerator::global()->bounded(3),-70.0,0.75+QRandomGenerator::global()->generateDouble()*.55});if(QRandomGenerator::global()->bounded(1000)<22)coins_.append({QRandomGenerator::global()->bounded(3),-20.0,1});for(auto&o:obstacles_){o.y+=v*o.factor;if(o.lane==lane_&&o.y>348&&o.y<456){finish();break;}if(o.y>480&&o.factor>0){score_+=2;o.factor=0;}}obstacles_.erase(std::remove_if(obstacles_.begin(),obstacles_.end(),[](const Obstacle&o){return o.y>520;}),obstacles_.end());for(auto&c:coins_)c.y+=v*.8;for(auto i=coins_.begin();i!=coins_.end();){if(i->lane==lane_&&i->y>365&&i->y<440){score_+=20;i=coins_.erase(i);}else if(i->y>520)i=coins_.erase(i);else ++i;}}
        else if(mode_==1){if(frame_%7!=0)return;QPoint head=snake_.first()+direction_;if(head.x()<0||head.x()>15||head.y()<0||head.y()>23||snake_.contains(head)||blocks_.contains(head)){finish();return;}snake_.prepend(head);if(head==food_){score_+=10*combo_;++combo_;food_={QRandomGenerator::global()->bounded(16),QRandomGenerator::global()->bounded(24)};if(score_%30==0)blocks_.append({QRandomGenerator::global()->bounded(16),QRandomGenerator::global()->bounded(24)});}else snake_.removeLast();}
        else {++frame_;targetClock_+=16;if(frame_%35==0)spawnTarget();for(auto&t:targets_)t.r-=.20;if(frame_%60==0)--lives_;targets_.erase(std::remove_if(targets_.begin(),targets_.end(),[](const Target&t){return t.r<5;}),targets_.end());if(lives_<=0)finish();}
        update();
    }
};

class NexusWindow final : public QMainWindow {
public:
    NexusWindow() {
        setWindowTitle(QString::fromLatin1(kAppName)); resize(1420, 920); setMinimumSize(980, 680);
        network_ = new QNetworkAccessManager(this);
        timerTick_ = new QTimer(this); timerTick_->setInterval(100); connect(timerTick_, &QTimer::timeout, this, &NexusWindow::updateTimer);
        clockTick_ = new QTimer(this); clockTick_->setInterval(1000); connect(clockTick_, &QTimer::timeout, this, &NexusWindow::updateClock);
        stopwatchTick_ = new QTimer(this); stopwatchTick_->setInterval(10); connect(stopwatchTick_, &QTimer::timeout, this, &NexusWindow::updateStopwatch);
        bgmPlayer_ = new QMediaPlayer(this); bgmAudio_ = new QAudioOutput(this); bgmPlayer_->setAudioOutput(bgmAudio_); bgmAudio_->setVolume(0.25);
        musicPlayer_ = new QMediaPlayer(this); musicAudio_ = new QAudioOutput(this); musicPlayer_->setAudioOutput(musicAudio_);
        connect(musicPlayer_, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus s){ if(s==QMediaPlayer::EndOfMedia) nextMusic(); });
        loadData(); buildUi(); applyTheme(); updateClock(); updateStopwatch(); refreshMemos(); refreshTodo(); refreshBookmarks(); refreshCalendarEvents(); refreshStorageSummary();
        clockTick_->start();
        sleepTick_ = new QTimer(this); sleepTick_->setInterval(15000); connect(sleepTick_, &QTimer::timeout, this, &NexusWindow::syncBedtimeOverlay); sleepTick_->start();
        connect(qApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state){ updatePrivacyOverlay(state == Qt::ApplicationActive); });
        statusBar()->showMessage(QStringLiteral("NEXUS CORE · ローカル機能を稼働中"));
        syncBedtimeOverlay(); updatePrivacyOverlay(QGuiApplication::applicationState() == Qt::ApplicationActive);
        if (autoNetwork_) QTimer::singleShot(900, this, &NexusWindow::loadWeather);
    }
    ~NexusWindow() override { saveData(); }

protected:
    void closeEvent(QCloseEvent* e) override { saveData(); QMainWindow::closeEvent(e); }
    void resizeEvent(QResizeEvent* e) override { QMainWindow::resizeEvent(e); if (screenOverlay_ && root_) screenOverlay_->setGeometry(root_->rect()); if (privacyOverlay_ && root_) privacyOverlay_->setGeometry(root_->rect()); if (sleepOverlay_ && root_) sleepOverlay_->setGeometry(root_->rect()); }
    void keyPressEvent(QKeyEvent* e) override {
        if (e->key() == Qt::Key_Escape) { if (screenProtected_) setScreenProtection(false); else if (devDialog_ && devDialog_->isVisible()) devDialog_->hide(); e->accept(); return; }
        if ((e->modifiers() & Qt::ControlModifier) && e->key() == Qt::Key_K) { showCommandPalette(); e->accept(); return; }
        if ((e->modifiers() & Qt::ControlModifier) && e->key() == Qt::Key_L && (e->modifiers() & Qt::ShiftModifier)) { setScreenProtection(!screenProtected_); e->accept(); return; }
        QMainWindow::keyPressEvent(e);
    }

private:
    QJsonObject data_;
    QString dataPath_ = appDataPath();
    QNetworkAccessManager* network_ = nullptr;
    QTimer *clockTick_ = nullptr, *timerTick_ = nullptr, *stopwatchTick_ = nullptr, *sleepTick_ = nullptr;
    QMediaPlayer *bgmPlayer_ = nullptr, *musicPlayer_ = nullptr;
    QAudioOutput *bgmAudio_ = nullptr, *musicAudio_ = nullptr;
    QBuffer* bgmBuffer_ = nullptr;
    QByteArray musicBgmData_;
    QStackedWidget* pages_ = nullptr;
    QWidget* sidebar_ = nullptr;
    QLabel *clockLabel_ = nullptr, *dateLabel_ = nullptr, *statusLabel_ = nullptr;
    AnalogClockWidget* analogClock_ = nullptr;
    QLabel *weatherIcon_ = nullptr, *weatherTemp_ = nullptr, *weatherInfo_ = nullptr, *weatherRain_ = nullptr;
    QComboBox* weatherPref_ = nullptr;
    QSpinBox* timerMinutes_ = nullptr;
    QLabel* timerDisplay_ = nullptr;
    QPushButton* timerStart_ = nullptr;
    qint64 timerRemainingMs_ = 300000;
    QElapsedTimer timerElapsed_;
    bool timerRunning_ = false;
    QElapsedTimer stopwatchElapsed_;
    qint64 stopwatchBaseMs_ = 0;
    bool stopwatchRunning_ = false;
    qint64 lapBaseMs_ = 0;
    int lapCount_ = 0;
    QLabel* stopwatchDisplay_ = nullptr;
    QListWidget* lapList_ = nullptr;
    QLineEdit *memoTitle_ = nullptr, *memoSearch_ = nullptr;
    QTextEdit* memoBody_ = nullptr;
    QListWidget* memoList_ = nullptr;
    QString editingMemoId_;
    QDateEdit* todoDate_ = nullptr;
    QLineEdit* todoInput_ = nullptr;
    QListWidget* todoList_ = nullptr;
    QLabel* todoSummary_ = nullptr;
    QComboBox* musicTrack_ = nullptr;
    QSlider* bgmVolume_ = nullptr;
    QLineEdit* calcInput_ = nullptr;
    QLabel* calcDisplay_ = nullptr;
    QCalendarWidget* calendar_ = nullptr;
    QDateEdit* eventDate_ = nullptr;
    QTimeEdit* eventTime_ = nullptr;
    QLineEdit* eventTitle_ = nullptr;
    QListWidget* eventList_ = nullptr;
    QLineEdit* translateInput_ = nullptr;
    QPlainTextEdit* translateOutput_ = nullptr;
    QComboBox *translateFrom_ = nullptr, *translateTo_ = nullptr;
    QLineEdit *assistantInput_ = nullptr, *bookmarkName_ = nullptr, *bookmarkUrl_ = nullptr;
    QListWidget* bookmarkList_ = nullptr;
    QComboBox* appCategory_ = nullptr;
    QListWidget* appList_ = nullptr;
    QLineEdit *networkLabel_ = nullptr;
    QLabel* networkResult_ = nullptr;
    QProgressBar* networkProgress_ = nullptr;
    QLineEdit *codeInput_ = nullptr;
    QPlainTextEdit *codeOutput_ = nullptr;
    QComboBox *codeFrom_ = nullptr, *codeTo_ = nullptr;
    QTextEdit *garbleInput_ = nullptr;
    QPlainTextEdit *garbleOutput_ = nullptr;
    QComboBox* garbleMode_ = nullptr;
    PaintCanvas* paintCanvas_ = nullptr;
    QDialog *paintDialog_ = nullptr, *urlDialog_ = nullptr, *devDialog_ = nullptr, *boardDialog_ = nullptr, *gameDialog_ = nullptr;
    MiniGameWidget* gameWidget_ = nullptr;
    QLineEdit* urlInput_ = nullptr;
    QLabel* urlResult_ = nullptr;
    QTextEdit* boardBody_ = nullptr;
    QLineEdit* boardTitle_ = nullptr;
    QComboBox* boardType_ = nullptr;
    QListWidget* boardList_ = nullptr;
    QCheckBox *autoNetworkCheck_ = nullptr, *anonCheck_ = nullptr, *blurCheck_ = nullptr;
    QSlider *accentSlider_ = nullptr, *blurSlider_ = nullptr, *iconSlider_ = nullptr;
    QLabel* backupSummary_ = nullptr;
    QLineEdit* adminCommand_ = nullptr;
    QPlainTextEdit* adminOutput_ = nullptr;
    bool autoNetwork_ = false, anonymousMode_ = false, screenProtected_ = false, privacyBlur_ = false;
    bool developerEnabled_ = false, adminEnabled_ = false, fastMode_ = false;
    int accentHue_ = 190, glassBlur_ = 12, iconSize_ = 84, selectedMusic_ = 0;
    QStringList musicFiles_;
    QStringList musicNames_;
    int currentMusicIndex_ = -1;
    bool musicShuffle_ = false, musicRepeat_ = false;
    QVector<QString> quickBookmarkNames_;
    QVector<QString> quickBookmarkUrls_;
    QString todoViewDate_;
    QVector<QPair<QString,QString>> appCategoryList_;
    QHash<QString, QWidget*> pageByKey_;
    QStringList pageNames_;

    void loadData() {
        QFile f(dataPath_);
        if (f.open(QIODevice::ReadOnly)) {
            QJsonParseError err; const auto doc = QJsonDocument::fromJson(f.readAll(), &err);
            if (err.error == QJsonParseError::NoError && doc.isObject()) data_ = doc.object();
        }
        autoNetwork_ = data_.value(QStringLiteral("autoNetwork")).toBool(false);
        anonymousMode_ = data_.value(QStringLiteral("anonymousMode")).toBool(false);
        privacyBlur_ = data_.value(QStringLiteral("privacyBlur")).toBool(false);
        accentHue_ = data_.value(QStringLiteral("accentHue")).toInt(190);
        glassBlur_ = data_.value(QStringLiteral("glassBlur")).toInt(12);
        iconSize_ = data_.value(QStringLiteral("iconSize")).toInt(84);
        fastMode_ = data_.value(QStringLiteral("fastMode")).toBool(false);
        lightTheme_ = data_.value(QStringLiteral("lightTheme")).toBool(false);
        sleepEnabled_ = data_.value(QStringLiteral("sleepEnabled")).toBool(false);
        const QString savedSleepStart = data_.value(QStringLiteral("sleepStart")).toString(QStringLiteral("22:00"));
        const QString savedSleepEnd = data_.value(QStringLiteral("sleepEnd")).toString(QStringLiteral("07:00"));
        if (QTime::fromString(savedSleepStart, QStringLiteral("HH:mm")).isValid()) sleepStart_ = savedSleepStart;
        if (QTime::fromString(savedSleepEnd, QStringLiteral("HH:mm")).isValid()) sleepEnd_ = savedSleepEnd;
        todoViewDate_ = QDate::currentDate().toString(Qt::ISODate);
        if (!data_.contains(QStringLiteral("bookmarks"))) {
            QJsonArray defaults;
            const QList<QPair<QString,QString>> links = {
                {QStringLiteral("Gmail"),QStringLiteral("https://mail.google.com")},
                {QStringLiteral("ドキュメント"),QStringLiteral("https://docs.google.com")},
                {QStringLiteral("スライド"),QStringLiteral("https://slides.google.com")},
                {QStringLiteral("スプレッドシート"),QStringLiteral("https://sheets.google.com")},
                {QStringLiteral("ドライブ"),QStringLiteral("https://drive.google.com")},
                {QStringLiteral("Word"),QStringLiteral("https://www.office.com/launch/word")},
                {QStringLiteral("Excel"),QStringLiteral("https://www.office.com/launch/excel")},
                {QStringLiteral("PowerPoint"),QStringLiteral("https://www.office.com/launch/powerpoint")},
                {QStringLiteral("Teams"),QStringLiteral("https://teams.microsoft.com")},
                {QStringLiteral("Outlook"),QStringLiteral("https://outlook.live.com")},
                {QStringLiteral("OneNote"),QStringLiteral("https://www.onenote.com")},
                {QStringLiteral("Copilot"),QStringLiteral("https://copilot.microsoft.com")},
                {QStringLiteral("Claude"),QStringLiteral("https://claude.ai")},
                {QStringLiteral("ChatGPT"),QStringLiteral("https://chatgpt.com")},
                {QStringLiteral("YouTube"),QStringLiteral("https://www.youtube.com")},
                {QStringLiteral("GitHub"),QStringLiteral("https://github.com")}
            };
            for (const auto& item : links) { QJsonObject o; o[QStringLiteral("name")] = item.first; o[QStringLiteral("url")] = item.second; defaults.append(o); }
            data_[QStringLiteral("bookmarks")] = defaults;
        }
        const QStringList cats = {QStringLiteral("Google"),QStringLiteral("Microsoft"),QStringLiteral("AI"),QStringLiteral("動画"),QStringLiteral("開発"),QStringLiteral("ゲーム")};
        for (const auto& cat : cats) appCategoryList_.push_back(qMakePair(cat, cat));
    }

    void saveData() {
        data_[QStringLiteral("autoNetwork")] = autoNetwork_;
        data_[QStringLiteral("anonymousMode")] = anonymousMode_;
        data_[QStringLiteral("privacyBlur")] = privacyBlur_;
        data_[QStringLiteral("accentHue")] = accentHue_;
        data_[QStringLiteral("glassBlur")] = glassBlur_;
        data_[QStringLiteral("iconSize")] = iconSize_;
        data_[QStringLiteral("fastMode")] = fastMode_;
        data_[QStringLiteral("lightTheme")] = lightTheme_;
        data_[QStringLiteral("sleepEnabled")] = sleepEnabled_;
        data_[QStringLiteral("sleepStart")] = sleepStart_;
        data_[QStringLiteral("sleepEnd")] = sleepEnd_;
        QSaveFile f(dataPath_);
        if (f.open(QIODevice::WriteOnly)) { f.write(QJsonDocument(data_).toJson(QJsonDocument::Indented)); f.commit(); }
    }

    QWidget* makePage(const QString& key, const QString& title, const QString& description) {
        auto* outer = new QWidget;
        auto* main = new QVBoxLayout(outer); main->setContentsMargins(24,20,24,28); main->setSpacing(14);
        auto* h = new QLabel(title); h->setObjectName(QStringLiteral("pageTitle")); main->addWidget(h);
        auto* d = makeHint(description); main->addWidget(d);
        auto* area = new QScrollArea; area->setWidgetResizable(true); area->setFrameShape(QFrame::NoFrame);
        auto* content = new QWidget; auto* layout = new QVBoxLayout(content); layout->setContentsMargins(0,0,8,12); layout->setSpacing(13);
        area->setWidget(content); main->addWidget(area,1); pages_->addWidget(outer); pageByKey_[key] = outer; pageNames_ << title;
        outer->setProperty("contentLayout", QVariant::fromValue<quintptr>(reinterpret_cast<quintptr>(layout)));
        return outer;
    }

    QVBoxLayout* pageLayout(const QString& key) const {
        QWidget* w = pageByKey_.value(key, nullptr); if (!w) return nullptr;
        auto* l = w->findChild<QVBoxLayout*>();
        // The first layout belongs to the outer page; content area is its second child layout.
        auto* area = w->findChild<QScrollArea*>();
        if (!area || !area->widget()) return l;
        return qobject_cast<QVBoxLayout*>(area->widget()->layout());
    }

    void addNav(const QString& key, const QString& label, const QString& icon) {
        auto* b = new QToolButton(sidebar_); b->setText(icon + QStringLiteral("  ") + label); b->setToolButtonStyle(Qt::ToolButtonTextOnly);
        b->setCursor(Qt::PointingHandCursor); b->setObjectName(QStringLiteral("nav_") + key); b->setProperty("navKey", key); b->setCheckable(true);
        navButtons_.push_back(b); sidebarLayout_->addWidget(b);
        connect(b, &QToolButton::clicked, this, [this,key]{ activatePage(key); });
    }

    QWidget* root_ = nullptr;
    QVBoxLayout* sidebarLayout_ = nullptr;
    QVector<QToolButton*> navButtons_;
    void buildUi() {
        root_ = new QWidget; root_->setObjectName(QStringLiteral("root")); setCentralWidget(root_);
        auto* rootLayout = new QHBoxLayout(root_); rootLayout->setContentsMargins(0,0,0,0); rootLayout->setSpacing(0);
        sidebar_ = new QFrame; sidebar_->setObjectName(QStringLiteral("sidebar")); sidebar_->setFixedWidth(236);
        sidebarLayout_ = new QVBoxLayout(sidebar_); sidebarLayout_->setContentsMargins(12,18,12,16); sidebarLayout_->setSpacing(5);
        auto* brand = new QLabel(QStringLiteral("◈  NEXUS\n      SUPER4.1")); brand->setObjectName(QStringLiteral("brand")); sidebarLayout_->addWidget(brand);
        auto* group1 = new QLabel(QStringLiteral("WORKSPACE")); group1->setObjectName(QStringLiteral("navGroup")); sidebarLayout_->addWidget(group1);
        addNav(QStringLiteral("home"),QStringLiteral("ホーム・検索"),QStringLiteral("⌂"));
        addNav(QStringLiteral("weather"),QStringLiteral("天気・ライブ情報"),QStringLiteral("☀"));
        addNav(QStringLiteral("daily"),QStringLiteral("メモ・Todo・予定"),QStringLiteral("▣"));
        addNav(QStringLiteral("tools"),QStringLiteral("タイマー・ツール"),QStringLiteral("◷"));
        addNav(QStringLiteral("create"),QStringLiteral("制作・CodeBridge"),QStringLiteral("✎"));
        addNav(QStringLiteral("security"),QStringLiteral("セキュリティ・プライバシー"),QStringLiteral("⬡"));
        addNav(QStringLiteral("settings"),QStringLiteral("カスタマイズ・バックアップ"),QStringLiteral("⚙"));
        addNav(QStringLiteral("developer"),QStringLiteral("開発者・管理センター"),QStringLiteral("⚠"));
        sidebarLayout_->addStretch();
        auto* sideNote = new QLabel(QStringLiteral("NEXUS CORE\nLOCAL WORKSPACE · 4.1")); sideNote->setObjectName(QStringLiteral("sideNote")); sidebarLayout_->addWidget(sideNote);
        rootLayout->addWidget(sidebar_);
        pages_ = new QStackedWidget; pages_->setObjectName(QStringLiteral("pages")); rootLayout->addWidget(pages_,1);
        buildHomePage(); buildWeatherPage(); buildDailyPage(); buildToolsPage(); buildCreatePage(); buildSecurityPage(); buildSettingsPage(); buildDeveloperPage();
        auto* bar = menuBar();
        auto* fileMenu = bar->addMenu(QStringLiteral("ファイル"));
        fileMenu->addAction(QStringLiteral("バックアップを書き出す"), this, &NexusWindow::exportBackup);
        fileMenu->addAction(QStringLiteral("バックアップを復元"), this, &NexusWindow::importBackup);
        fileMenu->addSeparator(); fileMenu->addAction(QStringLiteral("終了"), this, &QWidget::close);
        auto* viewMenu = bar->addMenu(QStringLiteral("表示")); viewMenu->addAction(QStringLiteral("コマンドランチャー  Ctrl+K"), this, &NexusWindow::showCommandPalette);
        viewMenu->addAction(QStringLiteral("画面保護  Ctrl+Shift+L"), this, [this]{setScreenProtection(!screenProtected_);});
        auto* helpMenu = bar->addMenu(QStringLiteral("ヘルプ")); helpMenu->addAction(QStringLiteral("利用規約・著作権"), this, &NexusWindow::showTerms);
        activatePage(QStringLiteral("home"));
    }

    void activatePage(const QString& key) {
        if (pageByKey_.contains(key)) pages_->setCurrentWidget(pageByKey_.value(key));
        for (auto* b : navButtons_) { const bool active = b->property("navKey").toString() == key; b->setChecked(active); }
        statusBar()->showMessage(QStringLiteral("表示中：%1").arg(pageByKey_.value(key)->findChild<QLabel*>(QStringLiteral("pageTitle"))->text()), 2200);
    }

    void buildHomePage() {
        auto* page = makePage(QStringLiteral("home"),QStringLiteral("NEXUS SUPER4.1"),QStringLiteral("FEATURE CONTROL CENTER · ローカル作業と情報確認の統合ダッシュボード"));
        auto* l = pageLayout(QStringLiteral("home"));
        auto* clockCard = makeCard(QStringLiteral("現在時刻 / LOCAL CLOCK"),l,QStringLiteral("clockCard")); auto* cl = qobject_cast<QVBoxLayout*>(clockCard->layout());
        auto* clockRow = new QHBoxLayout; clockRow->setSpacing(18);
        analogClock_ = new AnalogClockWidget; clockRow->addWidget(analogClock_, 0, Qt::AlignCenter);
        auto* digitalClock = new QWidget; auto* digitalLayout = new QVBoxLayout(digitalClock); digitalLayout->setContentsMargins(0,0,0,0); digitalLayout->setSpacing(2);
        clockLabel_ = new QLabel; clockLabel_->setObjectName(QStringLiteral("clock")); clockLabel_->setAlignment(Qt::AlignCenter); digitalLayout->addWidget(clockLabel_);
        dateLabel_ = new QLabel; dateLabel_->setAlignment(Qt::AlignCenter); dateLabel_->setObjectName(QStringLiteral("date")); digitalLayout->addWidget(dateLabel_);
        clockRow->addWidget(digitalClock, 1); cl->addLayout(clockRow);
        auto* searchRow = new QHBoxLayout; auto* search = new QLineEdit; search->setPlaceholderText(QStringLiteral("検索またはURLを入力（/ キーで移動）")); search->setObjectName(QStringLiteral("globalSearch"));
        auto* searchBtn = makeButton(QStringLiteral("検索")); searchRow->addWidget(search,1); searchRow->addWidget(searchBtn); cl->addLayout(searchRow);
        connect(searchBtn,&QPushButton::clicked,this,[this,search]{openSearch(search->text());});
        connect(search,&QLineEdit::returnPressed,this,[this,search]{openSearch(search->text());});
        auto* bCard = makeCard(QStringLiteral("ブックマーク"),l); auto* bl = qobject_cast<QVBoxLayout*>(bCard->layout());
        bookmarkList_ = new QListWidget; bookmarkList_->setObjectName(QStringLiteral("bookmarkList")); bookmarkList_->setMaximumHeight(180); bl->addWidget(bookmarkList_);
        auto* form = new QHBoxLayout; bookmarkName_ = new QLineEdit; bookmarkName_->setPlaceholderText(QStringLiteral("名前")); bookmarkUrl_ = new QLineEdit; bookmarkUrl_->setPlaceholderText(QStringLiteral("https://example.com")); auto* add = makeButton(QStringLiteral("追加")); form->addWidget(bookmarkName_); form->addWidget(bookmarkUrl_,2); form->addWidget(add); bl->addLayout(form);
        connect(add,&QPushButton::clicked,this,&NexusWindow::addBookmark);
        connect(bookmarkList_,&QListWidget::itemDoubleClicked,this,[this](QListWidgetItem* it){QJsonArray a=data_.value(QStringLiteral("bookmarks")).toArray();int i=bookmarkList_->row(it);if(i>=0&&i<a.size())openExternal(a[i].toObject().value(QStringLiteral("url")).toString());});
        auto* appCard = makeCard(QStringLiteral("アプリランチャー"),l); auto* al=qobject_cast<QVBoxLayout*>(appCard->layout());
        appCategory_ = new QComboBox; appCategory_->addItems({QStringLiteral("Google"),QStringLiteral("Microsoft"),QStringLiteral("AI"),QStringLiteral("動画"),QStringLiteral("開発"),QStringLiteral("ニュース")}); al->addWidget(appCategory_);
        appList_ = new QListWidget; appList_->setMaximumHeight(170); al->addWidget(appList_); populateAppList();
        connect(appCategory_,&QComboBox::currentTextChanged,this,[this]{populateAppList();});
        connect(appList_,&QListWidget::itemDoubleClicked,this,[this](QListWidgetItem* it){openExternal(it->data(Qt::UserRole).toString());});
        auto* actions = makeCard(QStringLiteral("クイックアクセス"),l); auto* ar=qobject_cast<QVBoxLayout*>(actions->layout()); auto* grid=new QGridLayout; ar->addLayout(grid);
        const QVector<QPair<QString,std::function<void()>>> items = {
            {QStringLiteral("💻 CodeBridge"),[this]{activatePage(QStringLiteral("create"));}}, {QStringLiteral("🛡 セキュリティ診断"),[this]{activatePage(QStringLiteral("security"));}},
            {QStringLiteral("🎨 お絵かき"),[this]{openPaintStudio();}}, {QStringLiteral("📰 ニュース"),[this]{openNews();}},
            {QStringLiteral("🔎 URLチェッカー"),[this]{openUrlChecker();}}, {QStringLiteral("🌙 おやすみ制限"),[this]{configureBedtime();}}, {QStringLiteral("🎮 ミニゲーム"),[this]{openMiniGame();}}
        };
        for(int i=0;i<items.size();++i){auto* b=makeButton(items[i].first);grid->addWidget(b,i/3,i%3);connect(b,&QPushButton::clicked,this,items[i].second);}
        l->addStretch();
    }

    void buildWeatherPage() {
        auto* page=makePage(QStringLiteral("weather"),QStringLiteral("ライブ情報・天気"),QStringLiteral("日本47都道府県の代表地点。地域を選び、手動更新または自動通信を許可して予報を取得します。"));
        auto* l=pageLayout(QStringLiteral("weather")); auto* card=makeCard(QStringLiteral("🌤 天気 / OPEN-METEO"),l,QStringLiteral("weatherCard"));auto* cl=qobject_cast<QVBoxLayout*>(card->layout());
        auto* row=new QHBoxLayout;weatherPref_=new QComboBox;for(const auto& p:prefectures())weatherPref_->addItem(p.name);int savedIndex=data_.value(QStringLiteral("weatherIndex")).toInt(27);weatherPref_->setCurrentIndex(std::clamp(savedIndex,0,static_cast<int>(prefectures().size())-1));auto* refresh=makeButton(QStringLiteral("🔄 更新"));row->addWidget(weatherPref_,1);row->addWidget(refresh);cl->addLayout(row);
        weatherIcon_=new QLabel(QStringLiteral("⛅"));weatherIcon_->setAlignment(Qt::AlignCenter);weatherIcon_->setObjectName(QStringLiteral("weatherIcon"));cl->addWidget(weatherIcon_);
        weatherTemp_=new QLabel(QStringLiteral("--°C"));weatherTemp_->setAlignment(Qt::AlignCenter);weatherTemp_->setObjectName(QStringLiteral("weatherTemp"));cl->addWidget(weatherTemp_);
        weatherInfo_=new QLabel(QStringLiteral("「更新」を押すと、選択した都道府県の予報を取得します。"));weatherInfo_->setWordWrap(true);cl->addWidget(weatherInfo_);
        weatherRain_=new QLabel;weatherRain_->setWordWrap(true);weatherRain_->setObjectName(QStringLiteral("weatherRain"));cl->addWidget(weatherRain_);
        connect(refresh,&QPushButton::clicked,this,&NexusWindow::loadWeather);connect(weatherPref_,&QComboBox::currentIndexChanged,this,[this](int i){data_[QStringLiteral("weatherIndex")]=i;saveData();weatherTemp_->setText(QStringLiteral("--°C"));weatherInfo_->setText(QStringLiteral("地域を変更しました。更新してください。"));weatherRain_->clear();if(autoNetwork_)loadWeather();});
        auto* note=makeCard(QStringLiteral("通信について"),l);auto* nl=qobject_cast<QVBoxLayout*>(note->layout());nl->addWidget(makeHint(QStringLiteral("天気データはOpen-Meteo APIから取得します。通信先にはIPアドレス等が伝わります。自動通信を無効にしている場合、更新ボタンを押したときだけ接続します。")));
    }

    void buildDailyPage() {
        auto* page=makePage(QStringLiteral("daily"),QStringLiteral("日々の作業"),QStringLiteral("メモ、日付別Todo、予定表、翻訳、掲示板記録をこの端末に保存します。"));auto* l=pageLayout(QStringLiteral("daily"));
        auto* memoCard=makeCard(QStringLiteral("📝 メモ"),l,QStringLiteral("memoCard"));auto* ml=qobject_cast<QVBoxLayout*>(memoCard->layout());
        memoSearch_=new QLineEdit;memoSearch_->setPlaceholderText(QStringLiteral("メモを検索"));ml->addWidget(memoSearch_);memoList_=new QListWidget;memoList_->setMaximumHeight(150);ml->addWidget(memoList_);
        memoTitle_=new QLineEdit;memoTitle_->setPlaceholderText(QStringLiteral("題名"));ml->addWidget(memoTitle_);memoBody_=new QTextEdit;memoBody_->setPlaceholderText(QStringLiteral("メモを入力…"));memoBody_->setMaximumHeight(140);ml->addWidget(memoBody_);
        auto* mr=new QHBoxLayout;auto* mnNew=makeButton(QStringLiteral("＋ 新規"));auto* mnSave=makeButton(QStringLiteral("💾 保存"));auto* mnPin=makeButton(QStringLiteral("📌 固定 / 解除"));auto* mnDel=makeButton(QStringLiteral("🗑 削除"));mr->addWidget(mnNew);mr->addWidget(mnSave);mr->addWidget(mnPin);mr->addWidget(mnDel);ml->addLayout(mr);
        connect(memoSearch_,&QLineEdit::textChanged,this,&NexusWindow::refreshMemos);connect(memoList_,&QListWidget::currentRowChanged,this,&NexusWindow::selectMemo);connect(mnNew,&QPushButton::clicked,this,[this]{editingMemoId_.clear();memoTitle_->clear();memoBody_->clear();memoTitle_->setFocus();});connect(mnSave,&QPushButton::clicked,this,&NexusWindow::saveMemo);connect(mnPin,&QPushButton::clicked,this,&NexusWindow::toggleMemoPin);connect(mnDel,&QPushButton::clicked,this,&NexusWindow::deleteMemo);
        auto* todoCard=makeCard(QStringLiteral("✅ 今日のTodo"),l,QStringLiteral("todoCard"));auto* tl=qobject_cast<QVBoxLayout*>(todoCard->layout());
        auto* tr=new QHBoxLayout;todoDate_=new QDateEdit(QDate::currentDate());todoDate_->setCalendarPopup(true);todoDate_->setDisplayFormat(QStringLiteral("yyyy-MM-dd"));todoInput_=new QLineEdit;todoInput_->setPlaceholderText(QStringLiteral("今日やることを追加…"));auto* todoAdd=makeButton(QStringLiteral("＋ 追加"));tr->addWidget(todoDate_);tr->addWidget(todoInput_,1);tr->addWidget(todoAdd);tl->addLayout(tr);todoSummary_=new QLabel;tl->addWidget(todoSummary_);todoList_=new QListWidget;todoList_->setMaximumHeight(220);tl->addWidget(todoList_);auto* todoBtns=new QHBoxLayout;auto* today=makeButton(QStringLiteral("📅 今日に戻る"));auto* clearDone=makeButton(QStringLiteral("✓ 完了分を削除"));todoBtns->addWidget(today);todoBtns->addWidget(clearDone);tl->addLayout(todoBtns);
        connect(todoAdd,&QPushButton::clicked,this,&NexusWindow::addTodo);connect(todoInput_,&QLineEdit::returnPressed,this,&NexusWindow::addTodo);connect(todoDate_,&QDateEdit::dateChanged,this,[this](const QDate& d){todoViewDate_=d.toString(Qt::ISODate);refreshTodo();});connect(today,&QPushButton::clicked,this,[this]{todoDate_->setDate(QDate::currentDate());});connect(clearDone,&QPushButton::clicked,this,&NexusWindow::clearCompletedTodo);
        auto* calCard=makeCard(QStringLiteral("📅 予定表"),l,QStringLiteral("calendarCard"));auto* cal=qobject_cast<QVBoxLayout*>(calCard->layout());calendar_=new QCalendarWidget;calendar_->setGridVisible(true);cal->addWidget(calendar_);auto* evrow=new QHBoxLayout;eventDate_=new QDateEdit(QDate::currentDate());eventDate_->setCalendarPopup(true);eventDate_->setDisplayFormat(QStringLiteral("yyyy-MM-dd"));eventTime_=new QTimeEdit(QTime(9,0));eventTitle_=new QLineEdit;eventTitle_->setPlaceholderText(QStringLiteral("予定"));auto* evadd=makeButton(QStringLiteral("追加"));evrow->addWidget(eventDate_);evrow->addWidget(eventTime_);evrow->addWidget(eventTitle_,1);evrow->addWidget(evadd);cal->addLayout(evrow);eventList_=new QListWidget;eventList_->setMaximumHeight(150);cal->addWidget(eventList_);
        connect(calendar_,&QCalendarWidget::selectionChanged,this,[this]{eventDate_->setDate(calendar_->selectedDate());refreshCalendarEvents();});connect(evadd,&QPushButton::clicked,this,&NexusWindow::addEvent);connect(eventTitle_,&QLineEdit::returnPressed,this,&NexusWindow::addEvent);
        auto* trCard=makeCard(QStringLiteral("🌐 翻訳"),l,QStringLiteral("translateCard"));auto* tr=qobject_cast<QVBoxLayout*>(trCard->layout());auto* langs=new QHBoxLayout;translateFrom_=new QComboBox;translateTo_=new QComboBox;const QStringList languageNames={QStringLiteral("日本語"),QStringLiteral("英語"),QStringLiteral("韓国語"),QStringLiteral("中国語（簡体）"),QStringLiteral("中国語（繁体）"),QStringLiteral("フランス語"),QStringLiteral("ドイツ語"),QStringLiteral("スペイン語"),QStringLiteral("イタリア語"),QStringLiteral("ポルトガル語"),QStringLiteral("ロシア語"),QStringLiteral("アラビア語"),QStringLiteral("ヒンディー語")};translateFrom_->addItems(languageNames);translateTo_->addItems(languageNames);translateFrom_->setCurrentIndex(1);translateTo_->setCurrentIndex(0);langs->addWidget(translateFrom_);langs->addWidget(translateTo_);auto* swap=makeButton(QStringLiteral("⇄"));langs->addWidget(swap);tr->addLayout(langs);translateInput_=new QLineEdit;translateInput_->setPlaceholderText(QStringLiteral("翻訳したい文章を入力"));tr->addWidget(translateInput_);auto* trBtns=new QHBoxLayout;auto* trGo=makeButton(QStringLiteral("Google翻訳で開く"));auto* trDeep=makeButton(QStringLiteral("DeepLで開く"));trBtns->addWidget(trGo);trBtns->addWidget(trDeep);tr->addLayout(trBtns);translateOutput_=new QPlainTextEdit;translateOutput_->setReadOnly(true);translateOutput_->setMaximumHeight(70);translateOutput_->setPlaceholderText(QStringLiteral("翻訳サイトで結果を確認してください。"));tr->addWidget(translateOutput_);
        connect(swap,&QPushButton::clicked,this,[this]{int f=translateFrom_->currentIndex();translateFrom_->setCurrentIndex(translateTo_->currentIndex());translateTo_->setCurrentIndex(f);});connect(trGo,&QPushButton::clicked,this,[this]{openTranslation(QStringLiteral("google"));});connect(trDeep,&QPushButton::clicked,this,[this]{openTranslation(QStringLiteral("deepl"));});
        auto* boardCard=makeCard(QStringLiteral("📝 NEXUS 掲示板記録"),l,QStringLiteral("boardCard"));auto* bl=qobject_cast<QVBoxLayout*>(boardCard->layout());auto* bnew=makeButton(QStringLiteral("掲示板を開く / 記録を書く"));bl->addWidget(bnew);connect(bnew,&QPushButton::clicked,this,&NexusWindow::openBoard);
        l->addStretch();
    }

    void buildToolsPage() {
        auto* page=makePage(QStringLiteral("tools"),QStringLiteral("ツール"),QStringLiteral("タイマー、BGM、ストップウォッチ、ネットワーク速度、音楽再生、電卓。"));auto* l=pageLayout(QStringLiteral("tools"));
        auto* timerCard=makeCard(QStringLiteral("⏱ タイマー"),l);auto* t=qobject_cast<QVBoxLayout*>(timerCard->layout());timerDisplay_=new QLabel(QStringLiteral("05:00"));timerDisplay_->setAlignment(Qt::AlignCenter);timerDisplay_->setObjectName(QStringLiteral("bigDigits"));t->addWidget(timerDisplay_);auto* tr=new QHBoxLayout;timerMinutes_=new QSpinBox;timerMinutes_->setRange(1,999);timerMinutes_->setValue(5);timerMinutes_->setSuffix(QStringLiteral(" 分"));timerStart_=makeButton(QStringLiteral("▶ スタート"));auto* reset=makeButton(QStringLiteral("↺ リセット"));tr->addWidget(timerMinutes_);tr->addWidget(timerStart_);tr->addWidget(reset);t->addLayout(tr);connect(timerStart_,&QPushButton::clicked,this,&NexusWindow::toggleTimer);connect(reset,&QPushButton::clicked,this,&NexusWindow::resetTimer);
        auto* bgmCard=makeCard(QStringLiteral("🎵 BGMプレイヤー"),l);auto* b=qobject_cast<QVBoxLayout*>(bgmCard->layout());auto* br=new QHBoxLayout;musicTrack_=new QComboBox;musicTrack_->addItems({QStringLiteral("宇宙・アンビエント"),QStringLiteral("ピアノ・リラックス"),QStringLiteral("シネマティック"),QStringLiteral("電子音楽"),QStringLiteral("集中・低刺激"),QStringLiteral("夜空・ドリーム")});auto* random=makeButton(QStringLiteral("🎲 ランダム"));br->addWidget(musicTrack_,1);br->addWidget(random);b->addLayout(br);auto* controls=new QHBoxLayout;auto* play=makeButton(QStringLiteral("▶ 再生"));auto* stop=makeButton(QStringLiteral("■ 停止"));bgmVolume_=new QSlider(Qt::Horizontal);bgmVolume_->setRange(0,100);bgmVolume_->setValue(25);controls->addWidget(play);controls->addWidget(stop);controls->addWidget(new QLabel(QStringLiteral("音量")));controls->addWidget(bgmVolume_,1);b->addLayout(controls);auto* bgmStatus=makeHint(QStringLiteral("全BGMをローカルで生成。音源ファイルや外部通信は不要です。"));b->addWidget(bgmStatus);
        connect(play,&QPushButton::clicked,this,&NexusWindow::playBgm);connect(stop,&QPushButton::clicked,bgmPlayer_,&QMediaPlayer::stop);connect(random,&QPushButton::clicked,this,[this]{musicTrack_->setCurrentIndex(QRandomGenerator::global()->bounded(musicTrack_->count()));playBgm();});connect(musicTrack_,&QComboBox::currentIndexChanged,this,[this]{if(bgmPlayer_->playbackState()==QMediaPlayer::PlayingState)playBgm();});connect(bgmVolume_,&QSlider::valueChanged,this,[this](int v){bgmAudio_->setVolume(v/100.0);});
        auto* swCard=makeCard(QStringLiteral("⏱ ストップウォッチ"),l);auto* sw=qobject_cast<QVBoxLayout*>(swCard->layout());stopwatchDisplay_=new QLabel(QStringLiteral("00:00.00"));stopwatchDisplay_->setAlignment(Qt::AlignCenter);stopwatchDisplay_->setObjectName(QStringLiteral("bigDigits"));sw->addWidget(stopwatchDisplay_);auto* swBtns=new QHBoxLayout;auto* swStart=makeButton(QStringLiteral("▶ スタート"));auto* swLap=makeButton(QStringLiteral("🏁 ラップ"));auto* swReset=makeButton(QStringLiteral("↺ リセット"));swBtns->addWidget(swStart);swBtns->addWidget(swLap);swBtns->addWidget(swReset);sw->addLayout(swBtns);lapList_=new QListWidget;lapList_->setMaximumHeight(130);sw->addWidget(lapList_);connect(swStart,&QPushButton::clicked,this,&NexusWindow::toggleStopwatch);connect(swLap,&QPushButton::clicked,this,&NexusWindow::addLap);connect(swReset,&QPushButton::clicked,this,&NexusWindow::resetStopwatch);
        auto* netCard=makeCard(QStringLiteral("📶 ネットワーク"),l);auto* n=qobject_cast<QVBoxLayout*>(netCard->layout());networkResult_=new QLabel(QStringLiteral("測定は手動操作のみです。"));networkResult_->setWordWrap(true);n->addWidget(networkResult_);networkProgress_=new QProgressBar;networkProgress_->setRange(0,0);networkProgress_->hide();n->addWidget(networkProgress_);auto* nbtn=makeButton(QStringLiteral("⚡ 下り速度を実測（約5MB）"));n->addWidget(nbtn);connect(nbtn,&QPushButton::clicked,this,&NexusWindow::measureNetwork);
        auto* musicCard=makeCard(QStringLiteral("🎧 ミュージックプレーヤー"),l);auto* m=qobject_cast<QVBoxLayout*>(musicCard->layout());auto* fileBtns=new QHBoxLayout;auto* choose=makeButton(QStringLiteral("📂 ファイルを選ぶ"));auto* clear=makeButton(QStringLiteral("🗑 クリア"));auto* prev=makeButton(QStringLiteral("⏮"));auto* mpPlay=makeButton(QStringLiteral("▶ / ⏸"));auto* next=makeButton(QStringLiteral("⏭"));auto* shuffle=makeButton(QStringLiteral("🔀"));auto* repeat=makeButton(QStringLiteral("🔁"));fileBtns->addWidget(choose);fileBtns->addWidget(clear);fileBtns->addWidget(prev);fileBtns->addWidget(mpPlay);fileBtns->addWidget(next);fileBtns->addWidget(shuffle);fileBtns->addWidget(repeat);m->addLayout(fileBtns);auto* musicStatus=makeHint(QStringLiteral("ファイル未選択"));musicStatus->setObjectName(QStringLiteral("musicStatus"));m->addWidget(musicStatus);auto* vol=new QSlider(Qt::Horizontal);vol->setRange(0,100);vol->setValue(80);m->addWidget(vol);
        connect(choose,&QPushButton::clicked,this,&NexusWindow::chooseMusic);connect(clear,&QPushButton::clicked,this,[this,musicStatus]{musicPlayer_->stop();musicFiles_.clear();musicNames_.clear();currentMusicIndex_=-1;musicStatus->setText(QStringLiteral("ファイル未選択"));});connect(prev,&QPushButton::clicked,this,[this]{if(currentMusicIndex_>0)playMusicAt(currentMusicIndex_-1);});connect(next,&QPushButton::clicked,this,&NexusWindow::nextMusic);connect(mpPlay,&QPushButton::clicked,this,[this]{if(musicPlayer_->playbackState()==QMediaPlayer::PlayingState)musicPlayer_->pause();else if(currentMusicIndex_<0)chooseMusic();else musicPlayer_->play();});connect(shuffle,&QPushButton::clicked,this,[this,shuffle]{musicShuffle_=!musicShuffle_;shuffle->setText(musicShuffle_?QStringLiteral("🔀 ON"):QStringLiteral("🔀"));});connect(repeat,&QPushButton::clicked,this,[this,repeat]{musicRepeat_=!musicRepeat_;repeat->setText(musicRepeat_?QStringLiteral("🔁 ON"):QStringLiteral("🔁"));});connect(vol,&QSlider::valueChanged,this,[this](int x){musicAudio_->setVolume(x/100.0);});
        auto* calcCard=makeCard(QStringLiteral("🧮 電卓"),l);auto* c=qobject_cast<QVBoxLayout*>(calcCard->layout());calcInput_=new QLineEdit;calcInput_->setPlaceholderText(QStringLiteral("例：(25 + 5) * 3"));c->addWidget(calcInput_);calcDisplay_=new QLabel(QStringLiteral("0"));calcDisplay_->setObjectName(QStringLiteral("calcDisplay"));calcDisplay_->setAlignment(Qt::AlignRight);c->addWidget(calcDisplay_);auto* calcGo=makeButton(QStringLiteral("計算"));c->addWidget(calcGo);connect(calcGo,&QPushButton::clicked,this,&NexusWindow::calculate);connect(calcInput_,&QLineEdit::returnPressed,this,&NexusWindow::calculate);
        auto* gameCard=makeCard(QStringLiteral("🎮 ミニゲーム"),l);auto* gm=qobject_cast<QVBoxLayout*>(gameCard->layout());auto* gameBtn=makeButton(QStringLiteral("ドライブ / スネーク / ターゲット"));gm->addWidget(gameBtn);connect(gameBtn,&QPushButton::clicked,this,&NexusWindow::openMiniGame);
        l->addStretch();
    }

    void buildCreatePage() {
        auto* page=makePage(QStringLiteral("create"),QStringLiteral("制作スタジオ"),QStringLiteral("CodeBridge、文字化けラボ、お絵かきスタジオ。変換結果は必ずビルド・実行前に確認してください。"));auto* l=pageLayout(QStringLiteral("create"));
        auto* cb=makeCard(QStringLiteral("💻 NEXUS CodeBridge"),l);auto* c=qobject_cast<QVBoxLayout*>(cb->layout());auto* langs=new QHBoxLayout;codeFrom_=new QComboBox;codeTo_=new QComboBox;const QStringList languageKeys={QStringLiteral("Python"),QStringLiteral("JavaScript"),QStringLiteral("Java"),QStringLiteral("Go"),QStringLiteral("R"),QStringLiteral("TypeScript"),QStringLiteral("C"),QStringLiteral("C#"),QStringLiteral("C++"),QStringLiteral("Cython"),QStringLiteral("Rust"),QStringLiteral("PHP"),QStringLiteral("HTML"),QStringLiteral("BASIC"),QStringLiteral("SQL"),QStringLiteral("Elixir"),QStringLiteral("Haskell")};codeFrom_->addItems(languageKeys);codeTo_->addItems(languageKeys);codeFrom_->setCurrentText(QStringLiteral("HTML"));codeTo_->setCurrentText(QStringLiteral("C++"));langs->addWidget(codeFrom_);langs->addWidget(new QLabel(QStringLiteral("→")));langs->addWidget(codeTo_);c->addLayout(langs);codeInput_=new QLineEdit;codeInput_->setPlaceholderText(QStringLiteral("変換する短いコードを入力。複数行は下の欄に貼り付けてください。"));c->addWidget(codeInput_);auto* src=new QPlainTextEdit;src->setPlaceholderText(QStringLiteral("ソースコード"));src->setMinimumHeight(130);c->addWidget(src);auto* convBtns=new QHBoxLayout;auto* convert=makeButton(QStringLiteral("変換"));auto* copy=makeButton(QStringLiteral("出力をコピー"));auto* save=makeButton(QStringLiteral("出力を保存"));convBtns->addWidget(convert);convBtns->addWidget(copy);convBtns->addWidget(save);c->addLayout(convBtns);codeOutput_=new QPlainTextEdit;codeOutput_->setReadOnly(false);codeOutput_->setMinimumHeight(150);codeOutput_->setPlaceholderText(QStringLiteral("変換結果"));c->addWidget(codeOutput_);
        connect(convert,&QPushButton::clicked,this,[this,src]{codeOutput_->setPlainText(convertCode(src->toPlainText(),codeFrom_->currentText(),codeTo_->currentText()));});connect(copy,&QPushButton::clicked,this,[this]{QApplication::clipboard()->setText(codeOutput_->toPlainText());});connect(save,&QPushButton::clicked,this,[this]{QString p=QFileDialog::getSaveFileName(this,QStringLiteral("コードを保存"),QStringLiteral("NEXUS_Converted.cpp"),QStringLiteral("Source files (*.cpp *.txt *.py *.ts *.js);;All files (*)"));if(!p.isEmpty()){QFile f(p);if(f.open(QIODevice::WriteOnly|QIODevice::Text))f.write(codeOutput_->toPlainText().toUtf8());}});
        auto* garble=makeCard(QStringLiteral("🧬 NEXUS 文字化けラボ"),l);auto* g=qobject_cast<QVBoxLayout*>(garble->layout());garbleInput_=new QTextEdit;garbleInput_->setPlaceholderText(QStringLiteral("テキストを入力"));garbleInput_->setMaximumHeight(100);g->addWidget(garbleInput_);garbleMode_=new QComboBox;garbleMode_->addItem(QStringLiteral("文字化け風"),QStringLiteral("moji"));garbleMode_->addItem(QStringLiteral("ノイズ"),QStringLiteral("noise"));garbleMode_->addItem(QStringLiteral("UTF-8 Base64"),QStringLiteral("b64"));g->addWidget(garbleMode_);auto* go=makeButton(QStringLiteral("変換"));g->addWidget(go);garbleOutput_=new QPlainTextEdit;garbleOutput_->setMaximumHeight(100);g->addWidget(garbleOutput_);auto* gr=new QHBoxLayout;auto* restore=makeButton(QStringLiteral("元に戻す"));auto* swap=makeButton(QStringLiteral("出力を入力へ"));auto* clear=makeButton(QStringLiteral("消去"));gr->addWidget(restore);gr->addWidget(swap);gr->addWidget(clear);g->addLayout(gr);
        connect(go,&QPushButton::clicked,this,&NexusWindow::runGarbler);connect(restore,&QPushButton::clicked,this,&NexusWindow::restoreGarbler);connect(swap,&QPushButton::clicked,this,[this]{garbleInput_->setPlainText(garbleOutput_->toPlainText());});connect(clear,&QPushButton::clicked,this,[this]{garbleInput_->clear();garbleOutput_->clear();garbleOriginal_.clear();});
        auto* art=makeCard(QStringLiteral("🎨 NEXUS お絵かきスタジオ"),l);auto* a=qobject_cast<QVBoxLayout*>(art->layout());auto* paint=makeButton(QStringLiteral("お絵かきスタジオを開く"));a->addWidget(paint);connect(paint,&QPushButton::clicked,this,&NexusWindow::openPaintStudio);
        auto* assistant=makeCard(QStringLiteral("🤖 NEXUS Assistant+"),l);auto* as=qobject_cast<QVBoxLayout*>(assistant->layout());assistantInput_=new QLineEdit;assistantInput_->setPlaceholderText(QStringLiteral("例：計算: (12+8)*3 / メモ: タイトル | 内容 / Todo: 内容"));as->addWidget(assistantInput_);auto* ask=makeButton(QStringLiteral("ローカルアシスト"));as->addWidget(ask);auto* answer=new QPlainTextEdit;answer->setReadOnly(true);answer->setMaximumHeight(120);answer->setObjectName(QStringLiteral("assistantAnswer"));as->addWidget(answer);connect(ask,&QPushButton::clicked,this,[this,answer]{answer->setPlainText(handleAssistant(assistantInput_->text()));});connect(assistantInput_,&QLineEdit::returnPressed,this,[this,answer]{answer->setPlainText(handleAssistant(assistantInput_->text()));});
        l->addStretch();
    }

    void buildSecurityPage() {
        auto* page=makePage(QStringLiteral("security"),QStringLiteral("セキュリティ・プライバシー"),QStringLiteral("このアプリ自身の設定・保存領域・入力URLをローカルで確認します。端末全体や他アプリをスキャンする機能ではありません。"));auto* l=pageLayout(QStringLiteral("security"));
        auto* privacy=makeCard(QStringLiteral("🕵️ プライバシー強化"),l);auto* p=qobject_cast<QVBoxLayout*>(privacy->layout());autoNetworkCheck_=new QCheckBox(QStringLiteral("天気などの外部通信を自動取得する"));autoNetworkCheck_->setChecked(autoNetwork_);p->addWidget(autoNetworkCheck_);anonCheck_=new QCheckBox(QStringLiteral("通信匿名モード（NEXUSからの外部通信・リンク起動をブロック）"));anonCheck_->setChecked(anonymousMode_);p->addWidget(anonCheck_);blurCheck_=new QCheckBox(QStringLiteral("ウィンドウが非アクティブになったら画面を隠す"));blurCheck_->setChecked(privacyBlur_);p->addWidget(blurCheck_);auto* scr=makeButton(QStringLiteral("🔒 画面保護 ON / OFF"));p->addWidget(scr);
        connect(autoNetworkCheck_,&QCheckBox::toggled,this,[this](bool v){if(v&&anonymousMode_){QSignalBlocker b(autoNetworkCheck_);autoNetworkCheck_->setChecked(false);QMessageBox::warning(this,QStringLiteral("通信制御"),QStringLiteral("通信匿名モードが有効なため、自動通信を有効にできません。"));return;}autoNetwork_=v;saveData();});connect(anonCheck_,&QCheckBox::toggled,this,[this](bool v){anonymousMode_=v;if(v&&autoNetwork_){autoNetwork_=false;QSignalBlocker b(autoNetworkCheck_);autoNetworkCheck_->setChecked(false);}saveData();});connect(blurCheck_,&QCheckBox::toggled,this,[this](bool v){privacyBlur_=v;saveData();});connect(scr,&QPushButton::clicked,this,[this]{setScreenProtection(!screenProtected_);});
        auto* url=makeCard(QStringLiteral("🔎 NEXUS URLチェッカー"),l);auto* u=qobject_cast<QVBoxLayout*>(url->layout());urlInput_=new QLineEdit;urlInput_->setPlaceholderText(QStringLiteral("https://example.com"));u->addWidget(urlInput_);auto* check=makeButton(QStringLiteral("URLをローカル検査"));u->addWidget(check);urlResult_=new QLabel;urlResult_->setWordWrap(true);u->addWidget(urlResult_);connect(check,&QPushButton::clicked,this,&NexusWindow::checkUrl);
        auto* report=makeCard(QStringLiteral("🛡️ セキュリティ・プライバシーレポート"),l);auto* rl=qobject_cast<QVBoxLayout*>(report->layout());auto* scan=makeButton(QStringLiteral("🔍 今すぐチェック"));rl->addWidget(scan);auto* output=new QPlainTextEdit;output->setReadOnly(true);output->setMinimumHeight(220);rl->addWidget(output);auto* export=makeButton(QStringLiteral("レポートを保存"));rl->addWidget(export);connect(scan,&QPushButton::clicked,this,[this,output]{output->setPlainText(generateSecurityReport());});connect(export,&QPushButton::clicked,this,[this,output]{QString p=QFileDialog::getSaveFileName(this,QStringLiteral("診断レポート"),QStringLiteral("NEXUS_SecurityReport.txt"));if(!p.isEmpty()){QFile f(p);if(f.open(QIODevice::WriteOnly|QIODevice::Text))f.write(output->toPlainText().toUtf8());}});
        l->addStretch();
    }

    void buildSettingsPage() {
        auto* page=makePage(QStringLiteral("settings"),QStringLiteral("カスタマイズ・バックアップ"),QStringLiteral("アクセントカラーや表示設定を調整し、NEXUSが保存したデータをJSONで退避・復元します。"));auto* l=pageLayout(QStringLiteral("settings"));
        auto* appearance=makeCard(QStringLiteral("🎨 外観・描画制御"),l);auto* a=qobject_cast<QVBoxLayout*>(appearance->layout());accentSlider_=new QSlider(Qt::Horizontal);accentSlider_->setRange(0,359);accentSlider_->setValue(accentHue_);a->addWidget(new QLabel(QStringLiteral("アクセント色相")));a->addWidget(accentSlider_);blurSlider_=new QSlider(Qt::Horizontal);blurSlider_->setRange(0,30);blurSlider_->setValue(glassBlur_);a->addWidget(new QLabel(QStringLiteral("ガラスのぼかし")));a->addWidget(blurSlider_);iconSlider_=new QSlider(Qt::Horizontal);iconSlider_->setRange(56,120);iconSlider_->setValue(iconSize_);a->addWidget(new QLabel(QStringLiteral("アイコンサイズ")));a->addWidget(iconSlider_);auto* theme=makeButton(QStringLiteral("テーマを切り替える"));a->addWidget(theme);
        connect(accentSlider_,&QSlider::valueChanged,this,[this](int v){accentHue_=v;applyTheme();saveData();});connect(blurSlider_,&QSlider::valueChanged,this,[this](int v){glassBlur_=v;applyTheme();saveData();});connect(iconSlider_,&QSlider::valueChanged,this,[this](int v){iconSize_=v;applyTheme();saveData();});connect(theme,&QPushButton::clicked,this,[this]{lightTheme_=!lightTheme_;applyTheme();saveData();});
        auto* backup=makeCard(QStringLiteral("💾 設定・メモの一括バックアップ"),l);auto* bl=qobject_cast<QVBoxLayout*>(backup->layout());bl->addWidget(makeHint(QStringLiteral("ローカルデータをJSONファイルに保存・復元します。暗号化を有効にするとAES-256-GCMで暗号化されます。パスフレーズは忘れると復元できません。")));backupSummary_=new QLabel;bl->addWidget(backupSummary_);auto* row=new QHBoxLayout;auto* ex=makeButton(QStringLiteral("⬇ エクスポート"));auto* im=makeButton(QStringLiteral("⬆ インポート"));row->addWidget(ex);row->addWidget(im);bl->addLayout(row);connect(ex,&QPushButton::clicked,this,&NexusWindow::exportBackup);connect(im,&QPushButton::clicked,this,&NexusWindow::importBackup);
        auto* init=makeCard(QStringLiteral("初期化"),l);auto* il=qobject_cast<QVBoxLayout*>(init->layout());auto* reset=makeButton(QStringLiteral("すべて初期化"));il->addWidget(reset);connect(reset,&QPushButton::clicked,this,[this]{if(QMessageBox::warning(this,QStringLiteral("確認"),QStringLiteral("NEXUSの保存データを初期化します。この操作は元に戻せません。"),QMessageBox::Yes|QMessageBox::No)==QMessageBox::Yes){data_=QJsonObject();saveData();QMessageBox::information(this,QStringLiteral("初期化"),QStringLiteral("再起動すると初期設定で起動します。"));}});
        auto* info=makeCard(QStringLiteral("利用規約・著作権"),l);auto* inf=qobject_cast<QVBoxLayout*>(info->layout());auto* terms=makeButton(QStringLiteral("利用規約を表示"));inf->addWidget(terms);connect(terms,&QPushButton::clicked,this,&NexusWindow::showTerms);l->addStretch();refreshStorageSummary();
    }

    void buildDeveloperPage() {
        auto* page=makePage(QStringLiteral("developer"),QStringLiteral("開発者モード・管理センター"),QStringLiteral("NEXUSアプリ内の診断・保存データ確認・許可リスト式コマンドを提供します。OS管理者権限や他アプリのデータにはアクセスしません。"));auto* l=pageLayout(QStringLiteral("developer"));
        auto* access=makeCard(QStringLiteral("📌 管理者権限について"),l);auto* al=qobject_cast<QVBoxLayout*>(access->layout());auto* enable=makeButton(QStringLiteral("開発者モードを有効化"));auto* admin=makeButton(QStringLiteral("管理者権限をこのセッションで有効化"));auto* lock=makeButton(QStringLiteral("管理者権限を解除"));al->addWidget(makeHint(QStringLiteral("管理できる範囲はNEXUSアプリの設定・保存データと画面診断に限られます。OSや他アプリの管理権限ではありません。")));al->addWidget(enable);al->addWidget(admin);al->addWidget(lock);
        auto* storage=makeCard(QStringLiteral("🗄 保存データ一覧"),l);auto* sl=qobject_cast<QVBoxLayout*>(storage->layout());auto* refresh=makeButton(QStringLiteral("一覧を更新"));sl->addWidget(refresh);auto* dump=new QPlainTextEdit;dump->setReadOnly(true);dump->setMinimumHeight(160);sl->addWidget(dump);
        auto* console=makeCard(QStringLiteral("⌨ NEXUS 管理コマンド"),l);auto* cl=qobject_cast<QVBoxLayout*>(console->layout());adminCommand_=new QLineEdit;adminCommand_->setPlaceholderText(QStringLiteral("help / status / scan / keys / export / fast on|off / anon on|off"));cl->addWidget(adminCommand_);auto* run=makeButton(QStringLiteral("実行"));cl->addWidget(run);adminOutput_=new QPlainTextEdit;adminOutput_->setReadOnly(true);adminOutput_->setMinimumHeight(160);cl->addWidget(adminOutput_);
        connect(refresh,&QPushButton::clicked,this,[this,dump]{if(!developerEnabled_){dump->setPlainText(QStringLiteral("開発者モードを有効にしてください。"));return;}QString out;for(auto it=data_.begin();it!=data_.end();++it)out+=it.key()+QStringLiteral(" : ")+QString::number(it.value().toString().size())+QStringLiteral(" chars / ")+QString::number(it.value().toVariant().toString().size())+QStringLiteral(" visible value hidden\n");dump->setPlainText(out.isEmpty()?QStringLiteral("保存データなし"):out);});
        connect(enable,&QPushButton::clicked,this,[this,enable]{developerEnabled_=!developerEnabled_;if(!developerEnabled_)adminEnabled_=false;enable->setText(developerEnabled_?QStringLiteral("開発者モードを停止"):QStringLiteral("開発者モードを有効化"));});connect(admin,&QPushButton::clicked,this,[this]{if(!developerEnabled_){QMessageBox::warning(this,QStringLiteral("権限"),QStringLiteral("先に開発者モードを有効にしてください。"));return;}if(QMessageBox::question(this,QStringLiteral("確認"),QStringLiteral("このセッションで管理者権限を有効にしますか？"))==QMessageBox::Yes)adminEnabled_=true;});connect(lock,&QPushButton::clicked,this,[this]{adminEnabled_=false;});connect(run,&QPushButton::clicked,this,&NexusWindow::runAdminCommand);connect(adminCommand_,&QLineEdit::returnPressed,this,&NexusWindow::runAdminCommand);l->addStretch();
    }

    void applyTheme() {
        const QColor accent = QColor::fromHsv(accentHue_, 220, 255);
        const int cardAlpha = std::clamp(235 - glassBlur_ * 3, 120, 235);
        const int navFontSize = std::clamp(10 + (iconSize_ - 84) / 12, 8, 13);
        const QString baseBackground = lightTheme_ ? QStringLiteral("#101c32") : QStringLiteral("#030714");
        const QString mainText = lightTheme_ ? QStringLiteral("#f6fbff") : QStringLiteral("#eaf5ff");
        const QString css = QStringLiteral(
            "QMainWindow,QWidget#root{background-color:%4;background-image:url(:/nexus/cpc_wallpaper.jpg);background-position:center;background-repeat:no-repeat;color:%5;}"
            "QFrame#sidebar{background:rgba(4,10,28,245);border-right:1px solid %1;}"
            "QLabel#brand{font-size:21px;font-weight:800;letter-spacing:3px;color:%1;padding:8px 6px 22px;}"
            "QLabel#navGroup{color:#7fa6cb;font-size:10px;font-weight:700;letter-spacing:2px;padding:12px 6px 4px;}"
            "QToolButton{color:%5;text-align:left;padding:10px 11px;border:1px solid transparent;border-radius:10px;font-size:%3px;}"
            "QToolButton:hover,QToolButton:checked{background:rgba(27,115,190,75);border-color:%1;color:white;}"
            "QLabel#sideNote{color:#76c9ed;font-size:10px;letter-spacing:1px;line-height:1.6;padding:10px 6px;}"
            "QLabel#pageTitle{font-size:27px;font-weight:700;color:#f0f7ff;}"
            "QFrame[nexusCard=true]{background:rgba(6,14,34,%2);border:1px solid rgba(73,188,255,85);border-radius:15px;}"
            "QLabel#cardTitle{font-size:15px;font-weight:700;color:%1;padding-bottom:3px;}"
            "QLabel#hint{color:#a8c5e0;font-size:11px;}"
            "QLabel#clock{font-size:68px;font-weight:200;color:#f4fbff;letter-spacing:4px;}"
            "QLabel#date{font-size:14px;color:%1;letter-spacing:2px;}"
            "QLabel#bigDigits{font-size:42px;font-weight:200;color:#effaff;}"
            "QLabel#weatherIcon{font-size:52px;}QLabel#weatherTemp{font-size:40px;font-weight:200;color:#f7fcff;}"
            "QLabel#calcDisplay{font-size:32px;color:%1;padding:6px;}"
            "QLineEdit,QTextEdit,QPlainTextEdit,QComboBox,QSpinBox,QDoubleSpinBox,QDateEdit,QTimeEdit{background:rgba(1,5,18,220);color:#eaf5ff;border:1px solid rgba(99,181,240,100);border-radius:8px;padding:7px;selection-background-color:%1;}"
            "QPushButton{background:rgba(20,91,150,130);color:#f3f9ff;border:1px solid %1;border-radius:9px;padding:8px 12px;font-size:12px;}QPushButton:hover{background:rgba(37,133,199,190);}QPushButton:pressed{background:%1;}"
            "QListWidget,QCalendarWidget QWidget{background:rgba(0,5,18,210);color:#eaf5ff;border:1px solid rgba(99,181,240,70);border-radius:8px;}"
            "QListWidget::item{padding:6px;border-bottom:1px solid rgba(100,160,210,35);}QListWidget::item:selected{background:rgba(25,105,175,140);}"
            "QSlider::groove:horizontal{height:5px;background:#20334b;border-radius:2px;}QSlider::handle:horizontal{background:%1;width:14px;margin:-5px 0;border-radius:7px;}"
            "QProgressBar{background:#0c1830;border:1px solid #294b70;border-radius:6px;text-align:center;}QProgressBar::chunk{background:%1;border-radius:5px;}"
            "QMenuBar,QMenu{background:#061024;color:#eaf5ff;}QMenuBar::item:selected,QMenu::item:selected{background:rgba(45,130,195,140);}QStatusBar{background:#061024;color:#95c7eb;}"
        ).arg(accent.name()).arg(cardAlpha).arg(navFontSize).arg(baseBackground, mainText);
        setStyleSheet(css);
    }

    bool lightTheme_ = false;

    void refreshBookmarks() {
        if (!bookmarkList_) return; bookmarkList_->clear(); const auto arr=data_.value(QStringLiteral("bookmarks")).toArray();
        for (const auto& v:arr) {const auto o=v.toObject();auto* it=new QListWidgetItem(o.value(QStringLiteral("name")).toString()+QStringLiteral("  ·  ")+o.value(QStringLiteral("url")).toString());it->setData(Qt::UserRole,o.value(QStringLiteral("url")).toString());bookmarkList_->addItem(it);}
    }
    void addBookmark() {
        QString name=bookmarkName_->text().trimmed(),url=bookmarkUrl_->text().trimmed();if(name.isEmpty()||url.isEmpty()){QMessageBox::warning(this,QStringLiteral("入力"),QStringLiteral("名前とURLを入力してください。"));return;}QUrl u=QUrl::fromUserInput(url);if((u.scheme()!=QStringLiteral("https")&&u.scheme()!=QStringLiteral("http"))||u.host().isEmpty()){QMessageBox::warning(this,QStringLiteral("URL"),QStringLiteral("有効なHTTP/HTTPS URLを入力してください。"));return;}
        QJsonArray arr=data_.value(QStringLiteral("bookmarks")).toArray();if(arr.size()>=80){QMessageBox::warning(this,QStringLiteral("上限"),QStringLiteral("ブックマークは最大80件です。"));return;}QJsonObject o;o[QStringLiteral("name")]=name.left(100);o[QStringLiteral("url")]=u.toString();arr.append(o);data_[QStringLiteral("bookmarks")]=arr;saveData();bookmarkName_->clear();bookmarkUrl_->clear();refreshBookmarks();
    }
    void populateAppList() {
        if(!appList_||!appCategory_)return;appList_->clear();const QString c=appCategory_->currentText();QList<QPair<QString,QString>> apps;
        if(c==QStringLiteral("Google"))apps={{"Gmail","https://mail.google.com"},{"ドキュメント","https://docs.google.com"},{"スプレッドシート","https://sheets.google.com"},{"スライド","https://slides.google.com"},{"ドライブ","https://drive.google.com"},{"YouTube","https://www.youtube.com"}};
        else if(c==QStringLiteral("Microsoft"))apps={{"Word","https://www.office.com/launch/word"},{"Excel","https://www.office.com/launch/excel"},{"PowerPoint","https://www.office.com/launch/powerpoint"},{"Teams","https://teams.microsoft.com"},{"Outlook","https://outlook.live.com"},{"OneNote","https://www.onenote.com"},{"Copilot","https://copilot.microsoft.com"}};
        else if(c==QStringLiteral("AI"))apps={{"ChatGPT","https://chatgpt.com"},{"Gemini","https://gemini.google.com"},{"Claude","https://claude.ai"},{"Perplexity","https://www.perplexity.ai"}};
        else if(c==QStringLiteral("動画"))apps={{"YouTube","https://www.youtube.com"},{"TVer","https://tver.jp"},{"NHK ONE","https://www.web.nhk"}};
        else if(c==QStringLiteral("開発"))apps={{"GitHub","https://github.com"},{"Stack Overflow","https://stackoverflow.com"},{"Qt Documentation","https://doc.qt.io"}};
        else apps={{"Google News","https://news.google.com"},{"NHK","https://www3.nhk.or.jp/news/"},{"Reuters","https://www.reuters.com"},{"BBC","https://www.bbc.com/news"}};
        for(const auto& a:apps){auto* it=new QListWidgetItem(a.first);it->setData(Qt::UserRole,a.second);appList_->addItem(it);}
    }

    void openExternal(const QString& url) {
        if(anonymousMode_){QMessageBox::information(this,QStringLiteral("通信匿名モード"),QStringLiteral("通信匿名モードが有効です。外部サイトは開きません。"));return;}
        const QUrl u(url);if(u.scheme()!=QStringLiteral("https")&&u.scheme()!=QStringLiteral("http")){QMessageBox::warning(this,QStringLiteral("URL"),QStringLiteral("HTTP/HTTPS以外のリンクは開けません。"));return;}
        QDesktopServices::openUrl(u);
    }

    void openSearch(QString query) {
        query=query.trimmed();if(query.isEmpty())return;QUrl u=QUrl::fromUserInput(query);if((u.scheme()==QStringLiteral("http")||u.scheme()==QStringLiteral("https"))&&!u.host().isEmpty())openExternal(u.toString());else openExternal(QStringLiteral("https://www.google.com/search?q=")+encodeUrl(query));
    }

    void updateClock() {
        const QDateTime now=QDateTime::currentDateTime();if(clockLabel_)clockLabel_->setText(now.toString(QStringLiteral("HH:mm:ss")));if(dateLabel_)dateLabel_->setText(QLocale(QLocale::Japanese).toString(now.date(),QStringLiteral("yyyy年M月d日 dddd")));if(analogClock_)analogClock_->update();
    }

    void loadWeather() {
        if(anonymousMode_){weatherInfo_->setText(QStringLiteral("通信匿名モードが有効です。外部通信は停止しています。"));return;}
        if(!weatherPref_||!weatherInfo_)return;const auto p=prefectures().at(std::clamp(weatherPref_->currentIndex(),0,static_cast<int>(prefectures().size())-1));
        QUrl url(QStringLiteral("https://api.open-meteo.com/v1/forecast"));QUrlQuery q;q.addQueryItem(QStringLiteral("latitude"),QString::number(p.lat,'f',4));q.addQueryItem(QStringLiteral("longitude"),QString::number(p.lon,'f',4));q.addQueryItem(QStringLiteral("current"),QStringLiteral("temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m"));q.addQueryItem(QStringLiteral("hourly"),QStringLiteral("precipitation,precipitation_probability"));q.addQueryItem(QStringLiteral("daily"),QStringLiteral("temperature_2m_max,temperature_2m_min,precipitation_probability_max"));q.addQueryItem(QStringLiteral("wind_speed_unit"),QStringLiteral("ms"));q.addQueryItem(QStringLiteral("timezone"),QStringLiteral("Asia/Tokyo"));q.addQueryItem(QStringLiteral("past_days"),QStringLiteral("1"));q.addQueryItem(QStringLiteral("forecast_days"),QStringLiteral("2"));url.setQuery(q);
        weatherInfo_->setText(QStringLiteral("%1（%2付近）の天気を取得しています…").arg(p.name,p.city));weatherRain_->clear();QNetworkRequest req(url);req.setTransferTimeout(15000);auto* reply=network_->get(req);
        connect(reply,&QNetworkReply::finished,this,[this,reply,p]{const auto bytes=reply->readAll();if(reply->error()!=QNetworkReply::NoError){weatherInfo_->setText(QStringLiteral("天気を取得できませんでした：%1").arg(reply->errorString()));reply->deleteLater();return;}QJsonParseError e;auto doc=QJsonDocument::fromJson(bytes,&e);if(e.error!=QJsonParseError::NoError||!doc.isObject()){weatherInfo_->setText(QStringLiteral("天気データを解析できませんでした。"));reply->deleteLater();return;}const auto root=doc.object(),cur=root.value(QStringLiteral("current")).toObject();double temp=cur.value(QStringLiteral("temperature_2m")).toDouble(std::numeric_limits<double>::quiet_NaN());if(!std::isfinite(temp)){weatherInfo_->setText(QStringLiteral("気温データがありません。"));reply->deleteLater();return;}int code=cur.value(QStringLiteral("weather_code")).toInt();weatherIcon_->setText(weatherDescription(code).section(' ', -1));weatherTemp_->setText(QStringLiteral("%1°C").arg(temp,0,'f',1));weatherInfo_->setText(QStringLiteral("%1 / %2付近\n%3\n体感 %4°C · 湿度 %5% · 風速 %6 m/s · 降水量 %7 mm").arg(p.name).arg(p.city).arg(weatherDescription(code)).arg(cur.value(QStringLiteral("apparent_temperature")).toDouble(),0,'f',1).arg(cur.value(QStringLiteral("relative_humidity_2m")).toInt()).arg(cur.value(QStringLiteral("wind_speed_10m")).toDouble(),0,'f',1).arg(cur.value(QStringLiteral("precipitation")).toDouble(),0,'f',1));
            const auto hourly=root.value(QStringLiteral("hourly")).toObject();const auto times=hourly.value(QStringLiteral("time")).toArray(),rain=hourly.value(QStringLiteral("precipitation")).toArray(),prob=hourly.value(QStringLiteral("precipitation_probability")).toArray();QString lines=QStringLiteral("今後24時間の時間別降水量\n");for(int i=0;i<times.size()&&i<rain.size()&&i<24;++i){QString time=times[i].toString();lines+=QStringLiteral("%1  降水 %2 mm  確率 %3%\n").arg(time.mid(11,5)).arg(rain[i].toDouble(),0,'f',1).arg(i<prob.size()?prob[i].toInt():0);}weatherRain_->setText(lines);reply->deleteLater(); });
    }

    void toggleTimer() {
        if(timerRunning_){timerRemainingMs_=std::max<qint64>(0,timerRemainingMs_-timerElapsed_.elapsed());timerRunning_=false;timerTick_->stop();timerStart_->setText(QStringLiteral("▶ 再開"));updateTimer();}
        else {if(timerRemainingMs_<=0)timerRemainingMs_=timerMinutes_->value()*60000LL;timerElapsed_.start();timerRunning_=true;timerTick_->start();timerStart_->setText(QStringLiteral("⏸ 一時停止"));}
    }
    void resetTimer() {timerRunning_=false;timerTick_->stop();timerRemainingMs_=timerMinutes_->value()*60000LL;timerStart_->setText(QStringLiteral("▶ スタート"));updateTimer();}
    void updateTimer() {qint64 rem=timerRemainingMs_;if(timerRunning_)rem=std::max<qint64>(0,rem-timerElapsed_.elapsed());if(rem<=0&&timerRunning_){timerRunning_=false;timerTick_->stop();timerRemainingMs_=0;timerStart_->setText(QStringLiteral("▶ スタート"));QApplication::beep();QMessageBox::information(this,QStringLiteral("タイマー"),QStringLiteral("時間になりました。"));}if(timerDisplay_)timerDisplay_->setText(QStringLiteral("%1:%2").arg(rem/60000,2,10,QChar('0')).arg((rem/1000)%60,2,10,QChar('0')));}

    void toggleStopwatch() {if(stopwatchRunning_){stopwatchBaseMs_+=stopwatchElapsed_.elapsed();stopwatchRunning_=false;stopwatchTick_->stop();}else{stopwatchElapsed_.start();stopwatchRunning_=true;stopwatchTick_->start();}}
    qint64 stopwatchMs() const {return stopwatchBaseMs_+(stopwatchRunning_?stopwatchElapsed_.elapsed():0);}
    QString formatStopwatch(qint64 ms) const {qint64 cs=(ms/10)%100, total=ms/1000, sec=total%60, min=(total/60)%60, hr=total/3600;QString s=QStringLiteral("%1:%2.%3").arg(min,2,10,QChar('0')).arg(sec,2,10,QChar('0')).arg(cs,2,10,QChar('0'));if(hr)s=QStringLiteral("%1:").arg(hr,2,10,QChar('0'))+s;return s;}
    void updateStopwatch(){if(stopwatchDisplay_)stopwatchDisplay_->setText(formatStopwatch(stopwatchMs()));}
    void addLap(){if(!stopwatchRunning_&&stopwatchBaseMs_==0)return;qint64 total=stopwatchMs(),split=total-lapBaseMs_;++lapCount_;lapBaseMs_=total;if(lapList_)lapList_->insertItem(0,QStringLiteral("ラップ %1　%2　（合計 %3）").arg(lapCount_).arg(formatStopwatch(split),formatStopwatch(total)));while(lapList_->count()>50)delete lapList_->takeItem(lapList_->count()-1);}
    void resetStopwatch(){stopwatchRunning_=false;stopwatchTick_->stop();stopwatchBaseMs_=0;lapBaseMs_=0;lapCount_=0;if(lapList_)lapList_->clear();updateStopwatch();}

    QJsonArray memoArray() const {return data_.value(QStringLiteral("memos")).toArray();}
    void refreshMemos() {if(!memoList_)return;memoList_->clear();const QString q=memoSearch_?memoSearch_->text().trimmed():QString();const auto arr=memoArray();QVector<QJsonObject> sorted;for(const auto& v:arr){auto o=v.toObject();if(q.isEmpty()||o.value(QStringLiteral("title")).toString().contains(q,Qt::CaseInsensitive)||o.value(QStringLiteral("body")).toString().contains(q,Qt::CaseInsensitive))sorted.push_back(o);}std::sort(sorted.begin(),sorted.end(),[](const QJsonObject&a,const QJsonObject&b){if(a.value(QStringLiteral("pinned")).toBool()!=b.value(QStringLiteral("pinned")).toBool())return a.value(QStringLiteral("pinned")).toBool();return a.value(QStringLiteral("updated")).toString()>b.value(QStringLiteral("updated")).toString();});for(const auto&o:sorted){auto* it=new QListWidgetItem((o.value(QStringLiteral("pinned")).toBool()?QStringLiteral("📌 "):QString())+(o.value(QStringLiteral("title")).toString().isEmpty()?QStringLiteral("（無題）"):o.value(QStringLiteral("title")).toString())+QStringLiteral("\n")+o.value(QStringLiteral("body")).toString().left(60));it->setData(Qt::UserRole,o.value(QStringLiteral("id")));memoList_->addItem(it);}}
    void selectMemo(int row){if(row<0||!memoList_)return;QString id=memoList_->item(row)->data(Qt::UserRole).toString();for(const auto& v:memoArray()){auto o=v.toObject();if(o.value(QStringLiteral("id")).toString()==id){editingMemoId_=id;memoTitle_->setText(o.value(QStringLiteral("title")).toString());memoBody_->setPlainText(o.value(QStringLiteral("body")).toString());break;}}}
    void saveMemo(){QString title=memoTitle_->text().trimmed().left(100),body=memoBody_->toPlainText();if(body.size()>20000){QMessageBox::warning(this,QStringLiteral("メモ"),QStringLiteral("本文は20,000文字以内です。"));return;}if(title.isEmpty()&&body.trimmed().isEmpty())return;QJsonArray arr=memoArray();QString id=editingMemoId_.isEmpty()?QUuid::createUuid().toString(QUuid::WithoutBraces):editingMemoId_;bool found=false;for(int i=0;i<arr.size();++i){auto o=arr[i].toObject();if(o.value(QStringLiteral("id")).toString()==id){o[QStringLiteral("title")]=title;o[QStringLiteral("body")]=body;o[QStringLiteral("updated")]=QDateTime::currentDateTimeUtc().toString(Qt::ISODate);arr[i]=o;found=true;break;}}if(!found){QJsonObject o;o[QStringLiteral("id")]=id;o[QStringLiteral("title")]=title;o[QStringLiteral("body")]=body;o[QStringLiteral("created")]=QDateTime::currentDateTimeUtc().toString(Qt::ISODate);o[QStringLiteral("updated")]=o.value(QStringLiteral("created"));o[QStringLiteral("pinned")]=false;arr.prepend(o);}if(arr.size()>200)arr.removeAt(arr.size()-1);data_[QStringLiteral("memos")]=arr;editingMemoId_=id;saveData();refreshMemos();}
    void toggleMemoPin(){if(editingMemoId_.isEmpty())return;QJsonArray arr=memoArray();for(int i=0;i<arr.size();++i){auto o=arr[i].toObject();if(o.value(QStringLiteral("id")).toString()==editingMemoId_){o[QStringLiteral("pinned")]=!o.value(QStringLiteral("pinned")).toBool();arr[i]=o;break;}}data_[QStringLiteral("memos")]=arr;saveData();refreshMemos();}
    void deleteMemo(){if(editingMemoId_.isEmpty())return;if(QMessageBox::question(this,QStringLiteral("削除"),QStringLiteral("このメモを削除しますか？"))!=QMessageBox::Yes)return;QJsonArray arr;for(const auto& v:memoArray())if(v.toObject().value(QStringLiteral("id")).toString()!=editingMemoId_)arr.append(v);data_[QStringLiteral("memos")]=arr;editingMemoId_.clear();memoTitle_->clear();memoBody_->clear();saveData();refreshMemos();}

    QJsonObject todoObject() const {return data_.value(QStringLiteral("todos")).toObject();}
    QJsonArray todoItems() const {return todoObject().value(todoViewDate_).toArray();}
    void refreshTodo(){if(!todoList_||!todoDate_)return;todoList_->clear();int done=0;auto items=todoItems();for(int i=0;i<items.size();++i){auto o=items[i].toObject();bool checked=o.value(QStringLiteral("done")).toBool();if(checked)++done;auto* it=new QListWidgetItem(QStringLiteral("%1  %2").arg(checked?QStringLiteral("☑"):QStringLiteral("☐"),o.value(QStringLiteral("text")).toString()));it->setData(Qt::UserRole,i);if(checked)it->setForeground(QColor("#8794a8"));todoList_->addItem(it);}todoSummary_->setText(QStringLiteral("完了 %1 / %2 件").arg(done).arg(items.size()));}
    void addTodo(){QString text=todoInput_->text().trimmed().left(180);if(text.isEmpty())return;QJsonObject all=todoObject();QJsonArray items=all.value(todoViewDate_).toArray();if(items.size()>=200){QMessageBox::warning(this,QStringLiteral("Todo"),QStringLiteral("1日あたり200件までです。"));return;}QJsonObject o;o[QStringLiteral("text")]=text;o[QStringLiteral("done")]=false;o[QStringLiteral("created")]=QDateTime::currentDateTimeUtc().toString(Qt::ISODate);items.append(o);all[todoViewDate_]=items;data_[QStringLiteral("todos")]=all;todoInput_->clear();saveData();refreshTodo();}
    void clearCompletedTodo(){QJsonObject all=todoObject();QJsonArray result;for(const auto& v:todoItems())if(!v.toObject().value(QStringLiteral("done")).toBool())result.append(v);all[todoViewDate_]=result;data_[QStringLiteral("todos")]=all;saveData();refreshTodo();}

    void refreshCalendarEvents(){if(!eventList_||!eventDate_)return;eventList_->clear();QDate d=eventDate_->date();for(const auto& v:data_.value(QStringLiteral("events")).toArray()){auto o=v.toObject();if(QDate::fromString(o.value(QStringLiteral("date")).toString(),Qt::ISODate)==d)eventList_->addItem(o.value(QStringLiteral("time")).toString()+QStringLiteral("  ")+o.value(QStringLiteral("title")).toString());}}
    void addEvent(){QString title=eventTitle_->text().trimmed().left(180);if(title.isEmpty())return;QJsonArray arr=data_.value(QStringLiteral("events")).toArray();QJsonObject o;o[QStringLiteral("date")]=eventDate_->date().toString(Qt::ISODate);o[QStringLiteral("time")]=eventTime_->time().toString(QStringLiteral("HH:mm"));o[QStringLiteral("title")]=title;arr.append(o);data_[QStringLiteral("events")]=arr;saveData();eventTitle_->clear();refreshCalendarEvents();}

    void openTranslation(const QString& engine){QString text=translateInput_->text().trimmed();if(text.isEmpty())return;QString from=translateFrom_->currentText(),to=translateTo_->currentText();QString codeFrom=languageCode(from),codeTo=languageCode(to);QString url;if(engine==QStringLiteral("deepl"))url=QStringLiteral("https://www.deepl.com/translator#%1/%2/%3").arg(codeFrom).arg(codeTo).arg(encodeUrl(text));else url=QStringLiteral("https://translate.google.com/?sl=%1&tl=%2&text=%3&op=translate").arg(codeFrom).arg(codeTo).arg(encodeUrl(text));translateOutput_->setPlainText(QStringLiteral("外部翻訳サイトを開きました。入力文はサイト提供者へ送信されます。\n%1 → %2").arg(from,to));openExternal(url);}
    QString languageCode(const QString& name) const {static const QHash<QString,QString> m={{QStringLiteral("日本語"),QStringLiteral("ja")},{QStringLiteral("英語"),QStringLiteral("en")},{QStringLiteral("韓国語"),QStringLiteral("ko")},{QStringLiteral("中国語（簡体）"),QStringLiteral("zh")},{QStringLiteral("中国語（繁体）"),QStringLiteral("zh-TW")},{QStringLiteral("フランス語"),QStringLiteral("fr")},{QStringLiteral("ドイツ語"),QStringLiteral("de")},{QStringLiteral("スペイン語"),QStringLiteral("es")},{QStringLiteral("イタリア語"),QStringLiteral("it")},{QStringLiteral("ポルトガル語"),QStringLiteral("pt")},{QStringLiteral("ロシア語"),QStringLiteral("ru")},{QStringLiteral("アラビア語"),QStringLiteral("ar")},{QStringLiteral("ヒンディー語"),QStringLiteral("hi")}};return m.value(name,QStringLiteral("auto"));}

    void calculate(){try{SafeExpression parser(calcInput_->text());double v=parser.evaluate();calcDisplay_->setText(QString::number(v,'g',14));}catch(...){calcDisplay_->setText(QStringLiteral("式を確認してください"));}}
    void playBgm(){const int track=musicTrack_->currentIndex();musicBgmData_=makeSynthTrack(std::max(0,track));if(bgmBuffer_){bgmPlayer_->stop();bgmBuffer_->close();bgmBuffer_->deleteLater();}bgmBuffer_=new QBuffer(this);bgmBuffer_->setData(musicBgmData_);bgmBuffer_->open(QIODevice::ReadOnly);bgmPlayer_->setSourceDevice(bgmBuffer_,QUrl(QStringLiteral("nexus-bgm.wav")));bgmAudio_->setVolume(bgmVolume_->value()/100.0);bgmPlayer_->play();}

    void measureNetwork(){if(anonymousMode_){networkResult_->setText(QStringLiteral("通信匿名モードが有効です。測定を中止しました。"));return;}networkResult_->setText(QStringLiteral("Cloudflareから約5MBをダウンロードしています…"));networkProgress_->show();QElapsedTimer* timer=new QElapsedTimer;timer->start();QUrl url(QStringLiteral("https://speed.cloudflare.com/__down?bytes=5000000"));QNetworkRequest req(url);req.setTransferTimeout(30000);auto* reply=network_->get(req);connect(reply,&QNetworkReply::downloadProgress,this,[this](qint64 r,qint64 t){if(t>0)networkProgress_->setRange(0,static_cast<int>(t));networkProgress_->setValue(static_cast<int>(r));});connect(reply,&QNetworkReply::finished,this,[this,reply,timer]{qint64 bytes=reply->bytesAvailable();QByteArray body=reply->readAll();bytes=std::max<qint64>(bytes,body.size());double sec=std::max(0.001,timer->elapsed()/1000.0);networkProgress_->hide();if(reply->error()!=QNetworkReply::NoError)networkResult_->setText(QStringLiteral("測定失敗：%1").arg(reply->errorString()));else networkResult_->setText(QStringLiteral("下り速度の推定：%1 Mbps\n受信量：%2 / 所要時間：%3 秒\n※サーバー・回線・混雑状況により変動します。").arg((bytes*8.0/sec/1000000.0),0,'f',2).arg(bytesText(bytes)).arg(sec,0,'f',2));reply->deleteLater();delete timer;});}

    void chooseMusic(){QStringList files=QFileDialog::getOpenFileNames(this,QStringLiteral("音楽ファイルを選択"),QString(),QStringLiteral("Audio files (*.mp3 *.m4a *.wav *.flac *.ogg *.aac *.opus);;All files (*)"));if(files.isEmpty())return;for(const auto& f:files){if(!musicFiles_.contains(f)){musicFiles_<<f;musicNames_<<QFileInfo(f).fileName();}}if(currentMusicIndex_<0)playMusicAt(0);}
    void playMusicAt(int index){if(musicFiles_.isEmpty())return;currentMusicIndex_=(index+musicFiles_.size())%musicFiles_.size();musicPlayer_->setSource(QUrl::fromLocalFile(musicFiles_[currentMusicIndex_]));musicPlayer_->play();statusBar()->showMessage(QStringLiteral("再生中：%1").arg(musicNames_.value(currentMusicIndex_)),3000);}
    void nextMusic(){if(musicFiles_.isEmpty())return;if(musicRepeat_&&currentMusicIndex_>=0){playMusicAt(currentMusicIndex_);return;}int next=musicShuffle_?QRandomGenerator::global()->bounded(musicFiles_.size()):(currentMusicIndex_+1)%musicFiles_.size();playMusicAt(next);}

    QString convertCode(const QString& source,const QString& from,const QString& to){
        if(from==to)return source;QStringList lines=source.split('\n');QStringList converted;
        auto trim=QString();bool hadPrint=false;
        for(const QString& raw:lines){trim=raw.trimmed();if(trim.isEmpty()){converted<<QString();continue;}if(trim.startsWith(QStringLiteral("#"))||trim.startsWith(QStringLiteral("//"))){QString c=trim.mid(trim.startsWith(QStringLiteral("//"))?2:1).trimmed();converted<<(to==QStringLiteral("Python")||to==QStringLiteral("R")||to==QStringLiteral("Ruby")?QStringLiteral("# ")+c:QStringLiteral("// ")+c);continue;}
            QRegularExpression printRe(QStringLiteral("^(?:print|console\\.log|System\\.out\\.println|fmt\\.Println)\\s*\\((.*)\\)\\s*;?$"));auto pm=printRe.match(trim);if(pm.hasMatch()){QString arg=pm.captured(1);if(to==QStringLiteral("Python"))converted<<QStringLiteral("print(%1)").arg(arg);else if(to==QStringLiteral("JavaScript")||to==QStringLiteral("TypeScript"))converted<<QStringLiteral("console.log(%1);").arg(arg);else if(to==QStringLiteral("C++"))converted<<QStringLiteral("std::cout << %1 << std::endl;").arg(arg);else if(to==QStringLiteral("C"))converted<<QStringLiteral("printf(\"%s\\n\", %1);").arg(arg);else if(to==QStringLiteral("Java"))converted<<QStringLiteral("System.out.println(%1);").arg(arg);else if(to==QStringLiteral("Go"))converted<<QStringLiteral("fmt.Println(%1)").arg(arg);else converted<<QStringLiteral("// PRINT %1").arg(arg);hadPrint=true;continue;}
            QRegularExpression assign(QStringLiteral("^(?:let |const |var )?([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(.+?);?$"));auto am=assign.match(trim);if(am.hasMatch()){QString name=am.captured(1),value=am.captured(2);if(to==QStringLiteral("Python"))converted<<QStringLiteral("%1 = %2").arg(name,value);else if(to==QStringLiteral("JavaScript")||to==QStringLiteral("TypeScript"))converted<<QStringLiteral("const %1 = %2;").arg(name,value);else if(to==QStringLiteral("C++"))converted<<QStringLiteral("auto %1 = %2;").arg(name,value);else if(to==QStringLiteral("C#"))converted<<QStringLiteral("var %1 = %2;").arg(name,value);else converted<<QStringLiteral("%1 = %2;").arg(name,value);continue;}
            if(to==QStringLiteral("HTML"))converted<<QStringLiteral("<p>%1</p>").arg(trim.toHtmlEscaped());else converted<<QStringLiteral("// 要確認: %1").arg(trim);
        }
        QString body=converted.join('\n');
        if(to==QStringLiteral("C++"))return QStringLiteral("#include <iostream>\n#include <string>\n\nint main() {\n%1\n    return 0;\n}\n").arg(indent(body,4));
        if(to==QStringLiteral("C"))return QStringLiteral("#include <stdio.h>\n\nint main(void) {\n%1\n    return 0;\n}\n").arg(indent(body,4));
        if(to==QStringLiteral("Java"))return QStringLiteral("public class Main {\n    public static void main(String[] args) {\n%1\n    }\n}\n").arg(indent(body,8));
        if(to==QStringLiteral("Go"))return QStringLiteral("package main\nimport \"fmt\"\n\nfunc main() {\n%1\n}\n").arg(indent(body,4));
        if(to==QStringLiteral("C#"))return QStringLiteral("using System;\n\nclass Program {\n    static void Main() {\n%1\n    }\n}\n").arg(indent(body,8));
        if(to==QStringLiteral("Rust"))return QStringLiteral("fn main() {\n%1\n}\n").arg(indent(body,4));
        if(to==QStringLiteral("HTML"))return QStringLiteral("<!doctype html>\n<html lang=\"ja\"><meta charset=\"utf-8\"><body><pre>\n%1\n</pre></body></html>").arg(body.toHtmlEscaped());
        Q_UNUSED(hadPrint);return body;
    }
    QString indent(const QString& text,int spaces) const {QString pad(spaces,' ');QStringList out;for(const auto& l:text.split('\n'))out<<pad+l;return out.join('\n');}

    QString garbleOriginal_;
    void runGarbler(){QString text=garbleInput_->toPlainText();if(text.isEmpty())return;garbleOriginal_=text;QString mode=garbleMode_->currentData().toString();if(mode==QStringLiteral("b64")){garbleOutput_->setPlainText(QStringLiteral("NEXUS_UTF8_B64:")+text.toUtf8().toBase64());return;}if(mode==QStringLiteral("noise")){QString pool=QStringLiteral("▓▒░╳ЖЯΩΨЖЩ§※〓∴∞†‡¤฿₿жヿﾇｼﾒ");QString out;int length=std::clamp(text.size()*2,12,8000);for(int i=0;i<length;++i){int ix=QRandomGenerator::global()->bounded(static_cast<int>(pool.size()));out+=pool[ix];if(i%61==60)out+='\n';}garbleOutput_->setPlainText(out);return;}QString symbols=QStringLiteral("縺繧譁蜿髫荳讖螟縲縻鬮驛�￠ƒ∂þæ¤§※〓▒▓░╳ЖЯΩΨжヿﾇｼﾒﾂ∴∞※");QString out;int idx=0;for(const auto& ch:text){if(ch.isSpace()){out+=ch;continue;}uint cp=ch.unicode();int n=(static_cast<quint64>(cp)*17+idx*13)%symbols.size();out+=symbols[n];if(idx%7==3)out+=symbols[(n+9+idx)%symbols.size()];++idx;}garbleOutput_->setPlainText(out);}
    void restoreGarbler(){QString s=garbleOutput_->toPlainText();if(s.startsWith(QStringLiteral("NEXUS_UTF8_B64:"))){QByteArray raw=QByteArray::fromBase64(s.mid(15).toLatin1());garbleInput_->setPlainText(QString::fromUtf8(raw));}else if(!garbleOriginal_.isEmpty())garbleInput_->setPlainText(garbleOriginal_);}

    QString handleAssistant(const QString& input){QString q=input.trimmed();if(q.isEmpty())return QStringLiteral("質問またはコマンドを入力してください。");if(q.startsWith(QStringLiteral("計算:"))||q.startsWith(QStringLiteral("電卓:"))){try{return QString::number(SafeExpression(q.section(':',1).trimmed()).evaluate(),'g',14);}catch(...){return QStringLiteral("式を読み取れませんでした。");}}if(q.startsWith(QStringLiteral("メモ:"))){QString rest=q.mid(3).trimmed();QString title=rest.section('|',0,0).trimmed();QString body=rest.contains('|')?rest.section('|',1).trimmed():rest;memoTitle_->setText(title);memoBody_->setPlainText(body);return QStringLiteral("メモ欄に内容を入力しました。「保存」を押してください。");}if(q.startsWith(QStringLiteral("Todo:"))){todoInput_->setText(q.mid(5).trimmed());addTodo();return QStringLiteral("Todoに追加しました。");}if(q.contains(QStringLiteral("時刻"))||q.contains(QStringLiteral("日付")))return QDateTime::currentDateTime().toString(QStringLiteral("yyyy年M月d日 HH:mm:ss"));if(q.startsWith(QStringLiteral("検索:"))){openSearch(q.mid(3).trimmed());return QStringLiteral("Web検索を開きました。");}if(q.contains(QStringLiteral("天気"))){activatePage(QStringLiteral("weather"));loadWeather();return QStringLiteral("天気ページで更新を開始しました。");}return QStringLiteral("ローカルAssistant+では、この質問への十分な回答はできません。必要に応じてChatGPT・Gemini・Web検索へ引き継いでください。\n\n対応コマンド：計算: (12+8)*3 / メモ: 題名 | 本文 / Todo: 内容 / 検索: キーワード");}

    void openMiniGame(){
        if(!gameDialog_){gameDialog_=new QDialog(this);gameDialog_->setWindowTitle(QStringLiteral("NEXUS ミニゲーム"));gameDialog_->resize(410,660);auto* l=new QVBoxLayout(gameDialog_);auto* modes=new QHBoxLayout;const QStringList labels={QStringLiteral("🚗 ドライブ"),QStringLiteral("🐍 スネーク"),QStringLiteral("🎯 ターゲット")};for(int i=0;i<labels.size();++i){auto* b=makeButton(labels[i]);modes->addWidget(b);connect(b,&QPushButton::clicked,this,[this,i]{if(gameWidget_)gameWidget_->setMode(i);});}l->addLayout(modes);gameWidget_=new MiniGameWidget;gameWidget_->setCloseHandler([this]{if(gameWidget_)gameWidget_->pause();if(gameDialog_)gameDialog_->hide();});gameWidget_->setSizePolicy(QSizePolicy::Fixed,QSizePolicy::Fixed);l->addWidget(gameWidget_,0,Qt::AlignHCenter);auto* ctrl=new QHBoxLayout;auto* left=makeButton(QStringLiteral("◀"));auto* right=makeButton(QStringLiteral("▶"));auto* turbo=makeButton(QStringLiteral("🔥 ターボ"));auto* close=makeButton(QStringLiteral("✕ 閉じる"));ctrl->addWidget(left);ctrl->addWidget(right);ctrl->addWidget(turbo);ctrl->addWidget(close);l->addLayout(ctrl);connect(left,&QPushButton::clicked,gameWidget_,[this]{gameWidget_->moveLane(-1);});connect(right,&QPushButton::clicked,gameWidget_,[this]{gameWidget_->moveLane(1);});connect(turbo,&QPushButton::clicked,gameWidget_,[this]{gameWidget_->turbo();});connect(close,&QPushButton::clicked,this,[this]{if(gameWidget_)gameWidget_->pause();if(gameDialog_)gameDialog_->hide();});connect(gameDialog_,&QDialog::rejected,gameWidget_,&MiniGameWidget::pause);gameWidget_->setFocus();}
        gameWidget_->setMode(0);gameDialog_->show();gameDialog_->raise();gameWidget_->setFocus();
    }

    void openPaintStudio(){if(paintDialog_){paintDialog_->show();paintDialog_->raise();return;}paintDialog_=new QDialog(this);paintDialog_->setWindowTitle(QStringLiteral("NEXUS お絵かきスタジオ"));paintDialog_->resize(1100,760);auto* l=new QVBoxLayout(paintDialog_);paintCanvas_=new PaintCanvas; if(data_.contains(QStringLiteral("draw"))){QImage saved=QImage::fromData(QByteArray::fromBase64(data_.value(QStringLiteral("draw")).toString().toLatin1()));paintCanvas_->loadImage(saved);} paintCanvas_->setChangeHandler([this](const QImage& image){QByteArray bytes;QBuffer buffer(&bytes);buffer.open(QIODevice::WriteOnly);image.save(&buffer,"JPEG",84);data_[QStringLiteral("draw")]=QString::fromLatin1(bytes.toBase64());saveData();});l->addWidget(paintCanvas_,1);auto* row=new QHBoxLayout;auto* tools=new QComboBox;tools->addItems({QStringLiteral("pen"),QStringLiteral("marker"),QStringLiteral("neon"),QStringLiteral("rainbow"),QStringLiteral("eraser"),QStringLiteral("spray"),QStringLiteral("line"),QStringLiteral("arrow"),QStringLiteral("rect"),QStringLiteral("ellipse"),QStringLiteral("triangle"),QStringLiteral("text"),QStringLiteral("stamp")});row->addWidget(tools);auto* color=new QPushButton(QStringLiteral("色を選択"));row->addWidget(color);auto* width=new QSlider(Qt::Horizontal);width->setRange(1,60);width->setValue(5);width->setMaximumWidth(160);row->addWidget(width);auto* fill=new QCheckBox(QStringLiteral("塗りつぶし"));row->addWidget(fill);auto* text=new QLineEdit(QStringLiteral("NEXUS!"));text->setPlaceholderText(QStringLiteral("文字"));row->addWidget(text,1);auto* undo=makeButton(QStringLiteral("↶ 戻す"));auto* redo=makeButton(QStringLiteral("↷ やり直す"));auto* clear=makeButton(QStringLiteral("消去"));auto* import=makeButton(QStringLiteral("画像を読み込む"));auto* save=makeButton(QStringLiteral("PNG保存"));row->addWidget(undo);row->addWidget(redo);row->addWidget(clear);row->addWidget(import);row->addWidget(save);l->addLayout(row);
        connect(tools,&QComboBox::currentTextChanged,paintCanvas_,&PaintCanvas::setTool);connect(color,&QPushButton::clicked,this,[this]{QColor c=QColorDialog::getColor(Qt::blue,paintDialog_);if(c.isValid())paintCanvas_->setPenColor(c);});connect(width,&QSlider::valueChanged,paintCanvas_,&PaintCanvas::setWidth);connect(fill,&QCheckBox::toggled,paintCanvas_,&PaintCanvas::setFill);connect(text,&QLineEdit::textChanged,paintCanvas_,&PaintCanvas::insertText);connect(undo,&QPushButton::clicked,paintCanvas_,&PaintCanvas::undo);connect(redo,&QPushButton::clicked,paintCanvas_,&PaintCanvas::redo);connect(clear,&QPushButton::clicked,paintCanvas_,&PaintCanvas::clearCanvas);connect(import,&QPushButton::clicked,this,[this]{QString p=QFileDialog::getOpenFileName(this,QStringLiteral("画像を選択"),QString(),QStringLiteral("Images (*.png *.jpg *.jpeg *.webp *.bmp)"));if(!p.isEmpty())paintCanvas_->importImage(p);});connect(save,&QPushButton::clicked,this,[this]{QString p=QFileDialog::getSaveFileName(this,QStringLiteral("PNG保存"),QStringLiteral("NEXUS-Drawing.png"),QStringLiteral("PNG (*.png)"));if(!p.isEmpty()&&!paintCanvas_->savePng(p))QMessageBox::warning(this,QStringLiteral("保存"),QStringLiteral("画像を保存できませんでした。"));});paintDialog_->exec();}

    void openUrlChecker(){if(urlDialog_){urlDialog_->show();return;}urlDialog_=new QDialog(this);urlDialog_->setWindowTitle(QStringLiteral("NEXUS URLチェッカー"));urlDialog_->resize(600,320);auto* l=new QVBoxLayout(urlDialog_);urlInput_=new QLineEdit;urlInput_->setPlaceholderText(QStringLiteral("https://example.com"));l->addWidget(urlInput_);auto* b=makeButton(QStringLiteral("ローカル検査"));l->addWidget(b);urlResult_=new QLabel;urlResult_->setWordWrap(true);l->addWidget(urlResult_);connect(b,&QPushButton::clicked,this,&NexusWindow::checkUrl);urlDialog_->exec();}
    void checkUrl(){if(!urlInput_||!urlResult_)return;QString raw=urlInput_->text().trimmed();QUrl u=QUrl::fromUserInput(raw);QStringList alerts;if(raw.isEmpty()){urlResult_->setText(QStringLiteral("URLを入力してください。"));return;}if(u.host().isEmpty())alerts<<QStringLiteral("ホスト名を確認できません。");if(u.scheme()!=QStringLiteral("https"))alerts<<QStringLiteral("HTTPSではありません（暗号化されない可能性）。");if(u.userInfo().contains('@'))alerts<<QStringLiteral("URLにユーザー情報が含まれています。");if(u.host().contains(QStringLiteral("xn--")))alerts<<QStringLiteral("国際化ドメイン（Punycode）を含みます。表示名を慎重に確認してください。");static const QStringList shorteners={QStringLiteral("bit.ly"),QStringLiteral("t.co"),QStringLiteral("tinyurl.com"),QStringLiteral("goo.gl"),QStringLiteral("ow.ly"),QStringLiteral("is.gd"),QStringLiteral("buff.ly"),QStringLiteral("cutt.ly"),QStringLiteral("rebrand.ly"),QStringLiteral("t.ly")};if(shorteners.contains(u.host(),Qt::CaseInsensitive))alerts<<QStringLiteral("短縮URLです。遷移先が見えないため注意してください。");if(raw.contains('@'))alerts<<QStringLiteral("@ を含みます。ドメイン名をよく確認してください。");if(raw.contains(QRegularExpression(QStringLiteral("https?://[^/]+\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"))))alerts<<QStringLiteral("IPアドレス形式のホストです。");if(alerts.isEmpty())urlResult_->setText(QStringLiteral("重大な形式上の警告は検出されませんでした。安全を保証するものではありません。\n%1").arg(u.toString()));else urlResult_->setText(QStringLiteral("⚠ 注意点：\n・%1\n\nこの検査はURLの文字列のみを確認し、サイトの内容・証明書・実際の安全性を判定しません。").arg(alerts.join(QStringLiteral("\n・"))));}

    QString generateSecurityReport(){QString r=QStringLiteral("NEXUS SUPER4.1 セキュリティ・プライバシーレポート\n実行日時：%1\n\n").arg(QDateTime::currentDateTime().toString(Qt::ISODate));int checks=0,warn=0;auto line=[&](QString name,bool ok,QString detail){++checks;if(!ok)++warn;r+=QStringLiteral("[%1] %2：%3\n").arg(ok?QStringLiteral("OK"):QStringLiteral("注意"),name,detail);};line(QStringLiteral("ローカル保存ファイル"),QFileInfo::exists(dataPath_),QFileInfo::exists(dataPath_)?QStringLiteral("保存ファイルあり"):QStringLiteral("まだ作成されていません"));line(QStringLiteral("自動外部通信"),!autoNetwork_,autoNetwork_?QStringLiteral("許可されています"):QStringLiteral("停止中"));line(QStringLiteral("匿名モード"),anonymousMode_,anonymousMode_?QStringLiteral("外部アクセスをブロックしています"):QStringLiteral("無効"));line(QStringLiteral("URLスキーム制限"),true,QStringLiteral("HTTP/HTTPSのみを許可する設計"));line(QStringLiteral("暗号化バックアップ"),true,QStringLiteral("AES-256-GCM + PBKDF2-SHA256を使用（有効時）"));line(QStringLiteral("管理者セッション"),!adminEnabled_,adminEnabled_?QStringLiteral("このセッションで有効"):QStringLiteral("無効"));r+=QStringLiteral("\nチェック %1 件 / 要確認 %2 件\n\n重要：これはNEXUSアプリ内部の簡易セルフチェックです。OS、他アプリ、ネットワーク機器や外部サイトをスキャンしません。安全性を保証するものではありません。").arg(checks).arg(warn);return r;}

    void openBoard(){if(boardDialog_){boardDialog_->show();return;}boardDialog_=new QDialog(this);boardDialog_->setWindowTitle(QStringLiteral("NEXUS 掲示板記録"));boardDialog_->resize(850,620);auto* l=new QHBoxLayout(boardDialog_);auto* left=new QVBoxLayout;boardList_=new QListWidget;left->addWidget(boardList_);auto* export=makeButton(QStringLiteral("TXT保存"));left->addWidget(export);l->addLayout(left,1);auto* right=new QVBoxLayout;boardType_=new QComboBox;boardType_->addItems({QStringLiteral("感想"),QStringLiteral("近況"),QStringLiteral("お知らせ"),QStringLiteral("アイデア")});boardTitle_=new QLineEdit;boardTitle_->setPlaceholderText(QStringLiteral("題名"));boardBody_=new QTextEdit;boardBody_->setPlaceholderText(QStringLiteral("最近の感想、気づいたこと、近況、お知らせなど"));right->addWidget(boardType_);right->addWidget(boardTitle_);right->addWidget(boardBody_,1);auto* save=makeButton(QStringLiteral("💾 記録を保存"));auto* del=makeButton(QStringLiteral("🗑 選択した記録を削除"));right->addWidget(save);right->addWidget(del);l->addLayout(right,2);connect(boardList_,&QListWidget::currentRowChanged,this,[this](int row){if(row<0)return;auto arr=data_.value(QStringLiteral("bulletin")).toArray();if(row<arr.size()){auto o=arr[row].toObject();boardTitle_->setText(o.value(QStringLiteral("title")).toString());boardBody_->setPlainText(o.value(QStringLiteral("body")).toString());boardType_->setCurrentText(o.value(QStringLiteral("type")).toString());}});connect(save,&QPushButton::clicked,this,[this]{if(boardTitle_->text().trimmed().isEmpty()||boardBody_->toPlainText().trimmed().isEmpty())return;QJsonArray arr=data_.value(QStringLiteral("bulletin")).toArray();QJsonObject o;o[QStringLiteral("type")]=boardType_->currentText();o[QStringLiteral("title")]=boardTitle_->text().trimmed().left(100);o[QStringLiteral("body")]=boardBody_->toPlainText().left(4000);o[QStringLiteral("created")]=QDateTime::currentDateTimeUtc().toString(Qt::ISODate);arr.prepend(o);if(arr.size()>200)arr.removeAt(arr.size()-1);data_[QStringLiteral("bulletin")]=arr;saveData();refreshBoardList();});connect(del,&QPushButton::clicked,this,[this]{int row=boardList_->currentRow();QJsonArray arr=data_.value(QStringLiteral("bulletin")).toArray();if(row<0||row>=arr.size())return;arr.removeAt(row);data_[QStringLiteral("bulletin")]=arr;saveData();refreshBoardList();});connect(export,&QPushButton::clicked,this,[this]{QString p=QFileDialog::getSaveFileName(this,QStringLiteral("掲示板記録を保存"),QStringLiteral("NEXUS_Board.txt"));if(p.isEmpty())return;QString out;for(const auto& v:data_.value(QStringLiteral("bulletin")).toArray()){auto o=v.toObject();out+=QStringLiteral("[%1] %2\n%3\n\n").arg(o.value(QStringLiteral("type")).toString(),o.value(QStringLiteral("title")).toString(),o.value(QStringLiteral("body")).toString());}QFile f(p);if(f.open(QIODevice::WriteOnly|QIODevice::Text))f.write(out.toUtf8());});refreshBoardList();boardDialog_->exec();}
    void refreshBoardList(){if(!boardList_)return;boardList_->clear();for(const auto& v:data_.value(QStringLiteral("bulletin")).toArray()){auto o=v.toObject();boardList_->addItem(QStringLiteral("%1 · %2").arg(o.value(QStringLiteral("type")).toString(),o.value(QStringLiteral("title")).toString()));}}

    QByteArray encryptAesGcm(const QByteArray& plain,const QString& password,QJsonObject& metadata){
        QByteArray salt(16,Qt::Uninitialized),nonce(12,Qt::Uninitialized);if(RAND_bytes(reinterpret_cast<unsigned char*>(salt.data()),salt.size())!=1||RAND_bytes(reinterpret_cast<unsigned char*>(nonce.data()),nonce.size())!=1)throw std::runtime_error("random generation failed");
        QByteArray key(32,Qt::Uninitialized);if(PKCS5_PBKDF2_HMAC(password.toUtf8().constData(),password.toUtf8().size(),reinterpret_cast<unsigned char*>(salt.data()),salt.size(),250000,EVP_sha256(),key.size(),reinterpret_cast<unsigned char*>(key.data()))!=1)throw std::runtime_error("key derivation failed");
        EVP_CIPHER_CTX* ctx=EVP_CIPHER_CTX_new();if(!ctx)throw std::runtime_error("cipher context failed");QByteArray cipher(plain.size()+16,Qt::Uninitialized);int n=0,total=0;bool ok=EVP_EncryptInit_ex(ctx,EVP_aes_256_gcm(),nullptr,nullptr,nullptr)==1&&EVP_CIPHER_CTX_ctrl(ctx,EVP_CTRL_GCM_SET_IVLEN,nonce.size(),nullptr)==1&&EVP_EncryptInit_ex(ctx,nullptr,nullptr,reinterpret_cast<unsigned char*>(key.data()),reinterpret_cast<unsigned char*>(nonce.data()))==1&&EVP_EncryptUpdate(ctx,reinterpret_cast<unsigned char*>(cipher.data()),&n,reinterpret_cast<const unsigned char*>(plain.constData()),plain.size())==1;total=n;ok=ok&&EVP_EncryptFinal_ex(ctx,reinterpret_cast<unsigned char*>(cipher.data())+total,&n)==1;total+=n;cipher.resize(total);QByteArray tag(16,Qt::Uninitialized);ok=ok&&EVP_CIPHER_CTX_ctrl(ctx,EVP_CTRL_GCM_GET_TAG,tag.size(),tag.data())==1;EVP_CIPHER_CTX_free(ctx);if(!ok)throw std::runtime_error("encryption failed");metadata[QStringLiteral("salt")]=QString::fromLatin1(salt.toBase64());metadata[QStringLiteral("nonce")]=QString::fromLatin1(nonce.toBase64());metadata[QStringLiteral("tag")]=QString::fromLatin1(tag.toBase64());return cipher;
    }
    QByteArray decryptAesGcm(const QByteArray& cipher,const QString& password,const QJsonObject& m){QByteArray salt=QByteArray::fromBase64(m.value(QStringLiteral("salt")).toString().toLatin1()),nonce=QByteArray::fromBase64(m.value(QStringLiteral("nonce")).toString().toLatin1()),tag=QByteArray::fromBase64(m.value(QStringLiteral("tag")).toString().toLatin1());if(salt.size()!=16||nonce.size()!=12||tag.size()!=16)throw std::runtime_error("invalid encryption metadata");QByteArray pass=password.toUtf8(),key(32,Qt::Uninitialized);if(PKCS5_PBKDF2_HMAC(pass.constData(),pass.size(),reinterpret_cast<unsigned char*>(salt.data()),salt.size(),250000,EVP_sha256(),key.size(),reinterpret_cast<unsigned char*>(key.data()))!=1)throw std::runtime_error("key derivation failed");EVP_CIPHER_CTX* ctx=EVP_CIPHER_CTX_new();if(!ctx)throw std::runtime_error("cipher context failed");QByteArray plain(cipher.size()+16,Qt::Uninitialized);int n=0,total=0;bool ok=EVP_DecryptInit_ex(ctx,EVP_aes_256_gcm(),nullptr,nullptr,nullptr)==1&&EVP_CIPHER_CTX_ctrl(ctx,EVP_CTRL_GCM_SET_IVLEN,nonce.size(),nullptr)==1&&EVP_DecryptInit_ex(ctx,nullptr,nullptr,reinterpret_cast<unsigned char*>(key.data()),reinterpret_cast<unsigned char*>(nonce.data()))==1&&EVP_DecryptUpdate(ctx,reinterpret_cast<unsigned char*>(plain.data()),&n,reinterpret_cast<const unsigned char*>(cipher.constData()),cipher.size())==1;total=n;ok=ok&&EVP_CIPHER_CTX_ctrl(ctx,EVP_CTRL_GCM_SET_TAG,tag.size(),tag.data())==1&&EVP_DecryptFinal_ex(ctx,reinterpret_cast<unsigned char*>(plain.data())+total,&n)==1;total+=n;EVP_CIPHER_CTX_free(ctx);if(!ok)throw std::runtime_error("wrong passphrase or damaged backup");plain.resize(total);return plain;}

    void exportBackup(){QString path=QFileDialog::getSaveFileName(this,QStringLiteral("NEXUSバックアップを書き出す"),QStringLiteral("NEXUS_SUPER4.1_Backup.json"),QStringLiteral("JSON (*.json)"));if(path.isEmpty())return;QMessageBox::StandardButton choice=QMessageBox::question(this,QStringLiteral("バックアップ暗号化"),QStringLiteral("パスフレーズでAES-256-GCM暗号化しますか？\n「いいえ」の場合、JSONは暗号化されず個人データを含みます。"),QMessageBox::Yes|QMessageBox::No|QMessageBox::Cancel);if(choice==QMessageBox::Cancel)return;QJsonObject payload;payload[QStringLiteral("format")]=QStringLiteral("NEXUS_BACKUP");payload[QStringLiteral("version")]=1;payload[QStringLiteral("application")]=QString::fromLatin1(kAppName);payload[QStringLiteral("exportedAt")]=QDateTime::currentDateTimeUtc().toString(Qt::ISODate);payload[QStringLiteral("data")]=data_;QByteArray bytes;if(choice==QMessageBox::Yes){bool ok=false;QString pass=QInputDialog::getText(this,QStringLiteral("パスフレーズ"),QStringLiteral("12文字以上のパスフレーズ"),QLineEdit::Password,QString(),&ok);if(!ok)return;if(pass.size()<12){QMessageBox::warning(this,QStringLiteral("パスフレーズ"),QStringLiteral("12文字以上で設定してください。"));return;}try{QJsonObject meta;QByteArray cipher=encryptAesGcm(QJsonDocument(payload).toJson(QJsonDocument::Compact),pass,meta);QJsonObject encrypted;encrypted[QStringLiteral("format")]=QStringLiteral("NEXUS_BACKUP_ENCRYPTED");encrypted[QStringLiteral("version")]=1;encrypted[QStringLiteral("kdf")]=QStringLiteral("PBKDF2-SHA256-250000");encrypted[QStringLiteral("cipher")]=QStringLiteral("AES-256-GCM");for(auto it=meta.begin();it!=meta.end();++it)encrypted[it.key()]=it.value();encrypted[QStringLiteral("ciphertext")]=QString::fromLatin1(cipher.toBase64());bytes=QJsonDocument(encrypted).toJson(QJsonDocument::Indented);}catch(const std::exception&e){QMessageBox::critical(this,QStringLiteral("暗号化"),QString::fromUtf8(e.what()));return;}}else bytes=QJsonDocument(payload).toJson(QJsonDocument::Indented);QSaveFile f(path);if(!f.open(QIODevice::WriteOnly)||f.write(bytes)!=bytes.size()||!f.commit()){QMessageBox::critical(this,QStringLiteral("保存"),QStringLiteral("バックアップを保存できませんでした。"));return;}QMessageBox::information(this,QStringLiteral("完了"),QStringLiteral("バックアップを書き出しました。\n%1").arg(path));}

    QJsonValue decodeLegacyStorageValue(const QJsonObject& legacy, const QString& key) const {
        const QJsonValue raw = legacy.value(key);
        if (!raw.isString()) return raw;
        const QByteArray bytes = raw.toString().toUtf8();
        QJsonParseError error;
        const QJsonDocument parsed = QJsonDocument::fromJson(bytes, &error);
        if (error.error == QJsonParseError::NoError) {
            if (parsed.isArray()) return parsed.array();
            if (parsed.isObject()) return parsed.object();
        }
        // localStorage stores JSON primitives too; QJsonDocument expects an object/array root.
        const QJsonDocument wrapped = QJsonDocument::fromJson(QByteArray("[") + bytes + QByteArray("]"), &error);
        if (error.error == QJsonParseError::NoError && wrapped.isArray() && wrapped.array().size() == 1)
            return wrapped.array().first();
        return raw;
    }

    QString legacyTimestamp(const QJsonValue& value, const QString& fallback) const {
        if (value.isString()) {
            const QString text = value.toString();
            if (QDateTime::fromString(text, Qt::ISODate).isValid()) return text;
        }
        if (value.isDouble()) {
            const double n = value.toDouble();
            if (n > 0 && n < 4102444800000.0)
                return QDateTime::fromMSecsSinceEpoch(static_cast<qint64>(n), Qt::UTC).toString(Qt::ISODate);
        }
        return fallback;
    }

    QJsonObject migrateLegacyHtmlStorage(const QJsonObject& legacy) const {
        QJsonObject migrated;
        migrated[QStringLiteral("legacyHtmlStorage")] = legacy; // Preserve every old browser key, including values not mapped to a native control.

        const QJsonObject cfg = decodeLegacyStorageValue(legacy, QStringLiteral("cfg")).toObject();
        if (!cfg.isEmpty()) {
            migrated[QStringLiteral("accentHue")] = cfg.value(QStringLiteral("h")).toInt(190);
            migrated[QStringLiteral("glassBlur")] = cfg.value(QStringLiteral("bl")).toInt(12);
            migrated[QStringLiteral("iconSize")] = cfg.value(QStringLiteral("sz")).toInt(84);
            migrated[QStringLiteral("lightTheme")] = cfg.value(QStringLiteral("th")).toString() == QStringLiteral("light");
            migrated[QStringLiteral("autoNetwork")] = cfg.value(QStringLiteral("privacyAutoNetwork")).toBool(false);
            migrated[QStringLiteral("privacyBlur")] = cfg.value(QStringLiteral("privacyBlur")).toBool(false);
            if (cfg.value(QStringLiteral("bg")).isString()) migrated[QStringLiteral("legacyWallpaperData")] = cfg.value(QStringLiteral("bg"));
        }

        const QJsonArray oldBookmarks = decodeLegacyStorageValue(legacy, QStringLiteral("bm")).toArray();
        QJsonArray bookmarks;
        for (const QJsonValue& value : oldBookmarks) {
            const QJsonArray pair = value.toArray();
            if (pair.size() < 2) continue;
            const QString name = pair[0].toString().trimmed().left(100);
            const QUrl url = QUrl::fromUserInput(pair[1].toString());
            if (name.isEmpty() || url.host().isEmpty() || (url.scheme() != QStringLiteral("http") && url.scheme() != QStringLiteral("https"))) continue;
            QJsonObject item; item[QStringLiteral("name")] = name; item[QStringLiteral("url")] = url.toString(); bookmarks.append(item);
        }
        if (!bookmarks.isEmpty()) migrated[QStringLiteral("bookmarks")] = bookmarks;

        QJsonArray memos = decodeLegacyStorageValue(legacy, QStringLiteral("memos")).toArray();
        QJsonArray convertedMemos;
        for (const QJsonValue& value : memos) {
            QJsonObject old = value.toObject(); if (old.isEmpty()) continue;
            QJsonObject item;
            item[QStringLiteral("id")] = old.value(QStringLiteral("id")).toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
            item[QStringLiteral("title")] = old.value(QStringLiteral("title")).toString().left(100);
            item[QStringLiteral("body")] = old.value(QStringLiteral("body")).toString().left(20000);
            item[QStringLiteral("pinned")] = old.value(QStringLiteral("pin")).toBool(old.value(QStringLiteral("pinned")).toBool());
            const QString created = legacyTimestamp(old.value(QStringLiteral("c")), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
            item[QStringLiteral("created")] = created;
            item[QStringLiteral("updated")] = legacyTimestamp(old.value(QStringLiteral("t")), created);
            convertedMemos.append(item);
        }
        const QString oldMemo = decodeLegacyStorageValue(legacy, QStringLiteral("memo")).toString();
        if (convertedMemos.isEmpty() && !oldMemo.trimmed().isEmpty()) {
            QJsonObject item; item[QStringLiteral("id")] = QStringLiteral("legacy-memo"); item[QStringLiteral("title")] = QStringLiteral("旧形式メモ"); item[QStringLiteral("body")] = oldMemo.left(20000); item[QStringLiteral("pinned")] = false;
            const QString now = QDateTime::currentDateTimeUtc().toString(Qt::ISODate); item[QStringLiteral("created")] = now; item[QStringLiteral("updated")] = now; convertedMemos.append(item);
        }
        if (!convertedMemos.isEmpty()) migrated[QStringLiteral("memos")] = convertedMemos;

        const QJsonValue todos = decodeLegacyStorageValue(legacy, QStringLiteral("nexusDailyTodos"));
        if (todos.isObject()) migrated[QStringLiteral("todos")] = todos;

        const QJsonArray oldEvents = decodeLegacyStorageValue(legacy, QStringLiteral("ev")).toArray();
        QJsonArray events;
        for (const QJsonValue& value : oldEvents) {
            const QJsonObject old = value.toObject(); if (old.isEmpty()) continue;
            const QString date = old.value(QStringLiteral("d")).toString();
            const QString title = old.value(QStringLiteral("n")).toString().trimmed().left(180);
            if (!QDate::fromString(date, Qt::ISODate).isValid() || title.isEmpty()) continue;
            QJsonObject item; item[QStringLiteral("date")] = date; item[QStringLiteral("time")] = old.value(QStringLiteral("t")).toString(); item[QStringLiteral("title")] = title;
            item[QStringLiteral("done")] = old.value(QStringLiteral("x")).toBool(); item[QStringLiteral("reminder")] = old.value(QStringLiteral("a")).toString(); events.append(item);
        }
        if (!events.isEmpty()) migrated[QStringLiteral("events")] = events;

        const QJsonArray oldBulletin = decodeLegacyStorageValue(legacy, QStringLiteral("nexusBulletinRecordsV1")).toArray();
        QJsonArray bulletin;
        for (const QJsonValue& value : oldBulletin) {
            const QJsonObject old = value.toObject(); if (old.isEmpty()) continue;
            const QString title = old.value(QStringLiteral("title")).toString().trimmed().left(100);
            const QString body = old.value(QStringLiteral("body")).toString().left(4000);
            if (title.isEmpty() || body.trimmed().isEmpty()) continue;
            const QString oldType = old.value(QStringLiteral("type")).toString();
            QString type = QStringLiteral("その他");
            if (oldType == QStringLiteral("thought")) type = QStringLiteral("感想");
            else if (oldType == QStringLiteral("diary")) type = QStringLiteral("近況");
            else if (oldType == QStringLiteral("notice")) type = QStringLiteral("お知らせ");
            else if (oldType == QStringLiteral("idea")) type = QStringLiteral("アイデア");
            QJsonObject item; item[QStringLiteral("type")] = type; item[QStringLiteral("title")] = title; item[QStringLiteral("body")] = body;
            item[QStringLiteral("created")] = legacyTimestamp(old.value(QStringLiteral("createdAt")), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
            item[QStringLiteral("updated")] = legacyTimestamp(old.value(QStringLiteral("updatedAt")), item.value(QStringLiteral("created")).toString());
            bulletin.append(item);
        }
        if (!bulletin.isEmpty()) migrated[QStringLiteral("bulletin")] = bulletin;

        const QJsonValue draw = decodeLegacyStorageValue(legacy, QStringLiteral("draw"));
        if (draw.isString()) {
            QString encoded = draw.toString();
            const qsizetype comma = encoded.indexOf(QLatin1Char(','));
            if (encoded.startsWith(QStringLiteral("data:image/")) && comma >= 0) encoded = encoded.mid(comma + 1);
            migrated[QStringLiteral("draw")] = encoded;
        }
        const QJsonObject sleep = decodeLegacyStorageValue(legacy, QStringLiteral("nexusSleepRestrictionV1")).toObject();
        if (!sleep.isEmpty()) {
            migrated[QStringLiteral("sleepEnabled")] = sleep.value(QStringLiteral("enabled")).toBool(false);
            migrated[QStringLiteral("sleepStart")] = sleep.value(QStringLiteral("start")).toString(QStringLiteral("22:00"));
            migrated[QStringLiteral("sleepEnd")] = sleep.value(QStringLiteral("end")).toString(QStringLiteral("07:00"));
        }
        migrated[QStringLiteral("anonymousMode")] = decodeLegacyStorageValue(legacy, QStringLiteral("nexusCommunicationAnonMode")).toBool(false);
        return migrated;
    }

    void importBackup() {
        const QString path = QFileDialog::getOpenFileName(this, QStringLiteral("バックアップを選択"), QString(), QStringLiteral("JSON (*.json);;All files (*)"));
        if (path.isEmpty()) return;
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) { QMessageBox::warning(this, QStringLiteral("読込"), QStringLiteral("ファイルを開けません。")); return; }
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !doc.isObject()) { QMessageBox::warning(this, QStringLiteral("形式"), QStringLiteral("JSON形式が正しくありません。")); return; }
        QJsonObject root = doc.object();
        const QString format = root.value(QStringLiteral("format")).toString();
        if (format == QStringLiteral("NEXUS_BACKUP_ENCRYPTED") || format == QStringLiteral("NEXUS_ENCRYPTED_BACKUP")) {
            bool ok = false;
            const QString pass = QInputDialog::getText(this, QStringLiteral("復号"), QStringLiteral("バックアップ用パスフレーズ（12文字以上）"), QLineEdit::Password, QString(), &ok);
            if (!ok) return;
            try {
                QJsonObject meta = root;
                QByteArray cipher;
                if (format == QStringLiteral("NEXUS_ENCRYPTED_BACKUP")) {
                    if (root.value(QStringLiteral("version")).toInt() != 1 || root.value(QStringLiteral("cipher")).toString() != QStringLiteral("AES-256-GCM") || root.value(QStringLiteral("kdf")).toString() != QStringLiteral("PBKDF2-SHA-256") || root.value(QStringLiteral("iterations")).toInt() != 250000)
                        throw std::runtime_error("unsupported legacy encryption format");
                    const QByteArray combined = QByteArray::fromBase64(root.value(QStringLiteral("ciphertext")).toString().toLatin1());
                    if (combined.size() < 16) throw std::runtime_error("encrypted payload is truncated");
                    meta[QStringLiteral("nonce")] = root.value(QStringLiteral("iv"));
                    meta[QStringLiteral("tag")] = QString::fromLatin1(combined.right(16).toBase64());
                    cipher = combined.left(combined.size() - 16);
                } else {
                    cipher = QByteArray::fromBase64(root.value(QStringLiteral("ciphertext")).toString().toLatin1());
                }
                const QByteArray plain = decryptAesGcm(cipher, pass, meta);
                doc = QJsonDocument::fromJson(plain, &error);
                if (error.error != QJsonParseError::NoError || !doc.isObject()) throw std::runtime_error("invalid backup payload");
                root = doc.object();
            } catch (const std::exception& e) { QMessageBox::critical(this, QStringLiteral("復号"), QString::fromUtf8(e.what())); return; }
        }
        if (root.value(QStringLiteral("format")).toString() != QStringLiteral("NEXUS_BACKUP") || !root.value(QStringLiteral("data")).isObject()) {
            QMessageBox::warning(this, QStringLiteral("形式"), QStringLiteral("NEXUSバックアップではありません。")); return;
        }
        if (QMessageBox::warning(this, QStringLiteral("復元確認"), QStringLiteral("現在のNEXUS保存データをバックアップ内容で置き換えます。先に現在データを別ファイルへ退避してください。続けますか？"), QMessageBox::Yes | QMessageBox::No) != QMessageBox::Yes) return;
        const QJsonObject imported = root.value(QStringLiteral("data")).toObject();
        const bool legacyFormat = imported.contains(QStringLiteral("cfg")) || imported.contains(QStringLiteral("bm")) || imported.contains(QStringLiteral("nexusDailyTodos"));
        data_ = legacyFormat ? migrateLegacyHtmlStorage(imported) : imported;
        saveData();
        refreshStorageSummary();
        const QString message = legacyFormat
            ? QStringLiteral("HTML版のバックアップを読み込み、対応するメモ・Todo・予定・ブックマーク・描画・おやすみ設定を移行しました。未対応の保存キーも legacyHtmlStorage に保管しています。再起動してください。")
            : QStringLiteral("復元しました。アプリを再起動してください。");
        QMessageBox::information(this, QStringLiteral("復元"), message);
    }

    void refreshStorageSummary(){if(!backupSummary_)return;backupSummary_->setText(QStringLiteral("メモ %1件 / Todo日付 %2件 / 予定 %3件 / ブックマーク %4件 / 掲示板 %5件\n保存先：%6").arg(data_.value(QStringLiteral("memos")).toArray().size()).arg(data_.value(QStringLiteral("todos")).toObject().size()).arg(data_.value(QStringLiteral("events")).toArray().size()).arg(data_.value(QStringLiteral("bookmarks")).toArray().size()).arg(data_.value(QStringLiteral("bulletin")).toArray().size()).arg(dataPath_));}

    void updatePrivacyOverlay(bool applicationActive) {
        if (!root_) return;
        const bool shouldShow = privacyBlur_ && !applicationActive;
        if (shouldShow && !privacyOverlay_) {
            privacyOverlay_ = new QFrame(root_); privacyOverlay_->setObjectName(QStringLiteral("privacyOverlay"));
            privacyOverlay_->setStyleSheet(QStringLiteral("QFrame#privacyOverlay{background:rgba(1,5,18,248);border:2px solid rgba(110,220,255,150);border-radius:12px;} QLabel{color:#dff7ff;font-size:18px;font-weight:700;}"));
            auto* l = new QVBoxLayout(privacyOverlay_); auto* label = new QLabel(QStringLiteral("プライバシー保護中\nアプリに戻ると表示が再開します。")); label->setAlignment(Qt::AlignCenter); l->addWidget(label);
        }
        if (privacyOverlay_) { privacyOverlay_->setGeometry(root_->rect()); privacyOverlay_->setVisible(shouldShow); if (shouldShow) privacyOverlay_->raise(); }
    }

    void setScreenProtection(bool enabled){screenProtected_=enabled;if(!centralWidget())return;if(enabled){if(screenOverlay_)return;screenOverlay_=new QFrame(root_);screenOverlay_->setObjectName(QStringLiteral("screenOverlay"));screenOverlay_->setStyleSheet(QStringLiteral("QFrame#screenOverlay{background:rgba(0,4,18,245);border:2px solid #50dfff;border-radius:18px;} QLabel{color:#bbf4ff;font-size:20px;font-weight:700;}"));auto* l=new QVBoxLayout(screenOverlay_);auto* label=new QLabel(QStringLiteral("🔒 画面保護中\n\nCtrl + Shift + L または Esc で解除"));label->setAlignment(Qt::AlignCenter);l->addWidget(label);screenOverlay_->setGeometry(root_->rect());screenOverlay_->show();screenOverlay_->raise();}else if(screenOverlay_){screenOverlay_->deleteLater();screenOverlay_=nullptr;}}
    QFrame* screenOverlay_ = nullptr;
    QFrame* privacyOverlay_ = nullptr;
    QFrame* sleepOverlay_ = nullptr;
    bool sleepEnabled_ = false;
    QString sleepStart_ = QStringLiteral("22:00"), sleepEnd_ = QStringLiteral("07:00");
    qint64 sleepPreviewUntil_ = 0, sleepBypassUntil_ = 0;

    void showCommandPalette(){QStringList options={QStringLiteral("ホーム・検索"),QStringLiteral("天気"),QStringLiteral("メモ・Todo・予定"),QStringLiteral("タイマー・ツール"),QStringLiteral("CodeBridge・制作"),QStringLiteral("セキュリティ"),QStringLiteral("カスタマイズ・バックアップ"),QStringLiteral("開発者モード"),QStringLiteral("お絵かき"),QStringLiteral("URLチェッカー"),QStringLiteral("今日のニュース")};bool ok=false;QString choice=QInputDialog::getItem(this,QStringLiteral("NEXUS コマンドランチャー"),QStringLiteral("機能を選択または検索"),options,0,false,&ok);if(!ok)return;int i=options.indexOf(choice);static const QStringList keys={QStringLiteral("home"),QStringLiteral("weather"),QStringLiteral("daily"),QStringLiteral("tools"),QStringLiteral("create"),QStringLiteral("security"),QStringLiteral("settings"),QStringLiteral("developer")};if(i>=0&&i<keys.size())activatePage(keys[i]);else if(choice==QStringLiteral("お絵かき"))openPaintStudio();else if(choice==QStringLiteral("URLチェッカー"))openUrlChecker();else openNews();}
    void openNews(){QDialog d(this);d.setWindowTitle(QStringLiteral("今日のニュース"));d.resize(430,300);auto* l=new QVBoxLayout(&d);l->addWidget(makeHint(QStringLiteral("記事見出しや本文はリンク先で確認してください。")));const QVector<QPair<QString,QString>> links={{"Google News","https://news.google.com"},{"NHK NEWS","https://www3.nhk.or.jp/news/"},{"Reuters","https://www.reuters.com"},{"BBC News","https://www.bbc.com/news"},{"Yahoo!ニュース","https://news.yahoo.co.jp"}};for(const auto& item:links){auto* b=makeButton(item.first);l->addWidget(b);connect(b,&QPushButton::clicked,this,[this,item]{openExternal(item.second);});}d.exec();}
    bool bedtimeScheduleActive() const {
        if (!sleepEnabled_) return false;
        const QTime now = QTime::currentTime(), start = QTime::fromString(sleepStart_, QStringLiteral("HH:mm")), end = QTime::fromString(sleepEnd_, QStringLiteral("HH:mm"));
        if (!start.isValid() || !end.isValid() || start == end) return false;
        return start < end ? (now >= start && now < end) : (now >= start || now < end);
    }
    void syncBedtimeOverlay() {
        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        const bool preview = sleepPreviewUntil_ > now;
        if (sleepPreviewUntil_ && !preview) sleepPreviewUntil_ = 0;
        const bool active = preview || (bedtimeScheduleActive() && sleepBypassUntil_ <= now);
        if (!root_) return;
        if (!active) { if (sleepOverlay_) { sleepOverlay_->hide(); } return; }
        if (!sleepOverlay_) {
            sleepOverlay_ = new QFrame(root_); sleepOverlay_->setObjectName(QStringLiteral("sleepOverlay"));
            sleepOverlay_->setStyleSheet(QStringLiteral("QFrame#sleepOverlay{background:rgba(4,10,25,248);border:2px solid #82bfff;border-radius:18px;} QLabel{color:#e8f4ff;} QPushButton{background:#1e3552;border:1px solid #9bcaff;border-radius:9px;padding:9px 14px;color:white;}"));
            auto* layout = new QVBoxLayout(sleepOverlay_); layout->setAlignment(Qt::AlignCenter);
            auto* moon = new QLabel(QStringLiteral("☾")); moon->setAlignment(Qt::AlignCenter); moon->setStyleSheet(QStringLiteral("font-size:52px;color:#c4d9ff;")); layout->addWidget(moon);
            auto* title = new QLabel(QStringLiteral("おやすみ制限中")); title->setObjectName(QStringLiteral("sleepTitle")); title->setAlignment(Qt::AlignCenter); title->setStyleSheet(QStringLiteral("font-size:25px;font-weight:700;")); layout->addWidget(title);
            auto* msg = new QLabel; msg->setObjectName(QStringLiteral("sleepMessage")); msg->setWordWrap(true); msg->setAlignment(Qt::AlignCenter); layout->addWidget(msg);
            auto* detail = new QLabel; detail->setObjectName(QStringLiteral("sleepDetail")); detail->setAlignment(Qt::AlignCenter); layout->addWidget(detail);
            auto* actions = new QHBoxLayout; auto* brk = makeButton(QStringLiteral("5分だけ一時解除")); auto* manage = makeButton(QStringLiteral("設定を見直す")); actions->addWidget(brk); actions->addWidget(manage); layout->addLayout(actions);
            auto* note = new QLabel(QStringLiteral("この機能は自主的な休憩を助けるものです。端末全体をロックする機能ではありません。")); note->setWordWrap(true); note->setAlignment(Qt::AlignCenter); note->setStyleSheet(QStringLiteral("font-size:10px;color:#9eafc8;")); layout->addWidget(note);
            connect(brk, &QPushButton::clicked, this, [this]{ if (QMessageBox::question(this, QStringLiteral("一時解除"), QStringLiteral("おやすみ制限を5分だけ一時解除しますか？")) == QMessageBox::Yes) { sleepPreviewUntil_ = 0; sleepBypassUntil_ = QDateTime::currentMSecsSinceEpoch() + 5 * 60 * 1000; syncBedtimeOverlay(); } });
            connect(manage, &QPushButton::clicked, this, [this]{ sleepPreviewUntil_ = 0; sleepBypassUntil_ = QDateTime::currentMSecsSinceEpoch() + 10 * 60 * 1000; if (sleepOverlay_) sleepOverlay_->hide(); configureBedtime(); });
        }
        if (auto* title = sleepOverlay_->findChild<QLabel*>(QStringLiteral("sleepTitle"))) title->setText(preview ? QStringLiteral("おやすみ制限（テスト中）") : QStringLiteral("おやすみ制限中"));
        if (auto* msg = sleepOverlay_->findChild<QLabel*>(QStringLiteral("sleepMessage"))) msg->setText(preview ? QStringLiteral("休憩画面の表示テスト中です。約1分後に自動で戻ります。") : QStringLiteral("設定したおやすみ時間です。画面から離れて、目と体を休めましょう。"));
        if (auto* detail = sleepOverlay_->findChild<QLabel*>(QStringLiteral("sleepDetail"))) detail->setText(preview ? QStringLiteral("テストは約1分で終了します。") : QStringLiteral("設定時間：%1〜%2（端末の現地時刻）").arg(sleepStart_, sleepEnd_));
        sleepOverlay_->setGeometry(root_->rect()); sleepOverlay_->show(); sleepOverlay_->raise();
    }
    void configureBedtime() {
        QDialog dialog(this); dialog.setWindowTitle(QStringLiteral("NEXUS おやすみ制限")); dialog.resize(430, 260); auto* layout = new QVBoxLayout(&dialog);
        auto* enabled = new QCheckBox(QStringLiteral("おやすみ時間の制限を有効にする")); enabled->setChecked(sleepEnabled_); layout->addWidget(enabled);
        auto* form = new QFormLayout; auto* start = new QTimeEdit(QTime::fromString(sleepStart_, QStringLiteral("HH:mm"))); auto* end = new QTimeEdit(QTime::fromString(sleepEnd_, QStringLiteral("HH:mm"))); start->setDisplayFormat(QStringLiteral("HH:mm")); end->setDisplayFormat(QStringLiteral("HH:mm")); form->addRow(QStringLiteral("開始時刻"), start); form->addRow(QStringLiteral("終了時刻"), end); layout->addLayout(form);
        layout->addWidget(makeHint(QStringLiteral("日付をまたぐ時間帯に対応します。同じ開始・終了時刻は設定できません。これはアプリ内の自主的な休憩機能で、OS全体をロックするものではありません。")));
        auto* buttons = new QDialogButtonBox(QDialogButtonBox::Save | QDialogButtonBox::Close); auto* test = makeButton(QStringLiteral("🌙 休憩画面を1分テスト")); buttons->addButton(test, QDialogButtonBox::ActionRole); layout->addWidget(buttons);
        connect(test, &QPushButton::clicked, &dialog, [this, &dialog]{ sleepPreviewUntil_ = QDateTime::currentMSecsSinceEpoch() + 60000; sleepBypassUntil_ = 0; dialog.accept(); syncBedtimeOverlay(); });
        connect(buttons, &QDialogButtonBox::accepted, &dialog, [&dialog, enabled, start, end, this]{ if (start->time() == end->time()) { QMessageBox::warning(&dialog, QStringLiteral("時刻"), QStringLiteral("開始時刻と終了時刻を異なる時刻にしてください。")); return; } sleepEnabled_ = enabled->isChecked(); sleepStart_ = start->time().toString(QStringLiteral("HH:mm")); sleepEnd_ = end->time().toString(QStringLiteral("HH:mm")); sleepPreviewUntil_ = 0; sleepBypassUntil_ = 0; saveData(); dialog.accept(); syncBedtimeOverlay(); });
        connect(buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject); dialog.exec();
    }

    void showTerms(){const QString terms=QStringLiteral(
        "NEXUS SUPER4.1 利用規約\n\n第1条（提供内容）\n本ツールは、検索、ブックマーク、時計、天気、メモ、Todo、予定表、翻訳、音楽・BGM、お絵かき、ゲームなどの機能をひとつの画面で提供します。機能は予告なく追加・変更・終了することがあります。\n\n第2条（利用範囲）\n本ツールは、個人の非営利目的での利用に限ります。天気データの提供元が非営利利用に限って無償提供しているため、商用での利用はできません。\n\n第3条（禁止事項）\n法令または公序良俗に反する行為、他者の著作権・プライバシーその他の権利を侵害する行為、本ツールの無断での再配布・販売または改変したものの公開（制作者が許可した場合を除く）、外部サービスに過度な負荷をかける行為、他者になりすます行為、不正アクセスその他、本ツールや外部サービスの運営を妨げる行為を禁止します。\n\n第4条（データの取り扱い）\nメモ、Todo、予定、設定、お絵かきなどのデータは、このアプリのローカル保存領域に保存されます。本ツール自身はこれらのデータを制作者や第三者のサーバーへ送信しません。バックアップを暗号化しない場合、保存データは暗号化されません。共有端末では秘密情報を保存しないでください。\n\n第5条（外部サービス・リンク）\n外部サイト・サービスは各提供者のものであり、その内容、利用条件、個人情報の取り扱いは各提供者の定めに従います。本ツールと各社との間に提携・後援・推奨などの関係はありません。\n\n第6条（情報の正確性）\n天気、ニュースなどは参考情報であり、正確性・完全性・即時性を保証しません。\n\n第7条（免責）\n本ツールは現状のまま提供され、動作、安全性、特定目的への適合性を保証しません。法令で許される範囲で、制作者は利用による損害について責任を負いません。\n\n第8条（規約の変更）\n本規約は必要に応じて変更することがあります。\n\n第9条（準拠法）\n本規約は日本法に準拠します。\n\n本ツールの著作権\n元HTMLに記載された著作権者：GitHubアカウント『kinokokenatto』。利用者が作成したメモ・予定・お絵かきなどの権利は利用者に帰属します。\n\n※このC++移植版では画面構成と機能をQt Widgetsに再実装しています。元HTMLのブラウザDOM機能は、ネイティブアプリ向けの診断機能に置き換えています。" );QMessageBox box(this);box.setWindowTitle(QStringLiteral("利用規約・著作権"));box.setText(terms);box.setStandardButtons(QMessageBox::Ok);box.exec();}

    void runAdminCommand(){QString raw=adminCommand_->text().trimmed();adminCommand_->clear();if(!developerEnabled_){adminOutput_->appendPlainText(QStringLiteral("開発者モードを先に有効化してください。"));return;}QStringList args=raw.split(QRegularExpression(QStringLiteral("\\s+")),Qt::SkipEmptyParts);QString cmd=args.value(0).toLower(),arg=args.value(1).toLower(),result;if(cmd==QStringLiteral("help"))result=QStringLiteral("許可コマンド：help / status / scan / keys / export / fast on|off / anon on|off / network on|off / accent 0-359\n任意コード、シェル、OSコマンドは実行できません。");else if(cmd==QStringLiteral("status"))result=QStringLiteral("NEXUS SUPER4.1 / Developer=%1 / Admin=%2 / NetworkAuto=%3 / Anonymous=%4\nData=%5").arg(developerEnabled_).arg(adminEnabled_).arg(autoNetwork_).arg(anonymousMode_).arg(dataPath_);else if(cmd==QStringLiteral("scan"))result=generateSecurityReport();else if(cmd==QStringLiteral("keys")){for(auto it=data_.begin();it!=data_.end();++it)result+=it.key()+QStringLiteral("\n");}else if(cmd==QStringLiteral("export")){if(adminEnabled_){exportBackup();result=QStringLiteral("バックアップ画面を開きました。");}else result=QStringLiteral("管理者権限が必要です。");}else if(cmd==QStringLiteral("fast")&&(arg==QStringLiteral("on")||arg==QStringLiteral("off"))){fastMode_=arg==QStringLiteral("on");saveData();result=QStringLiteral("fastMode=%1").arg(arg);}else if(cmd==QStringLiteral("anon")&&(arg==QStringLiteral("on")||arg==QStringLiteral("off"))){anonymousMode_=arg==QStringLiteral("on");if(anonCheck_)anonCheck_->setChecked(anonymousMode_);saveData();result=QStringLiteral("anonymousMode=%1").arg(arg);}else if(cmd==QStringLiteral("network")&&(arg==QStringLiteral("on")||arg==QStringLiteral("off"))){if(arg==QStringLiteral("on")&&anonymousMode_)result=QStringLiteral("匿名モードを先にOFFにしてください。");else{autoNetwork_=arg==QStringLiteral("on");if(autoNetworkCheck_)autoNetworkCheck_->setChecked(autoNetwork_);saveData();result=QStringLiteral("autoNetwork=%1").arg(arg);}}else if(cmd==QStringLiteral("accent")&&args.size()>1){bool ok=false;int v=args[1].toInt(&ok);if(ok&&v>=0&&v<=359){accentHue_=v;accentSlider_->setValue(v);saveData();result=QStringLiteral("accent=%1").arg(v);}else result=QStringLiteral("accent 0-359 を指定してください。");}else result=QStringLiteral("不明なコマンドです。help を入力してください。");adminOutput_->appendPlainText(QStringLiteral("> %1\n%2\n").arg(raw,result));}
};

} // namespace

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QApplication::setApplicationName(QString::fromLatin1(kAppName));
    QApplication::setOrganizationName(QStringLiteral("NEXUS"));
    QApplication::setApplicationVersion(QStringLiteral("4.1"));
    NexusWindow window;
    window.show();
    return app.exec();
}

