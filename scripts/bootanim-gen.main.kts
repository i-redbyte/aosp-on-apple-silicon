#!/usr/bin/env kotlin
// Генератор кадров bootanimation: байкер въезжает слева, тормозит и “едет на месте”.
// Запуск: kotlin bootanim-gen.main.kts <картинка.png> <папка-вывода>
// В папке появятся desc.txt, part0/ (въезд и надпись, 45 кадров) и part1/ (цикл, 30 кадров).
// Упаковка без сжатия:  cd <папка-вывода> && zip -0 -q -X -r ../bootanimation.zip desc.txt part0 part1

import java.awt.BasicStroke
import java.awt.Color
import java.awt.Font
import java.awt.RenderingHints
import java.awt.geom.Ellipse2D
import java.awt.image.BufferedImage
import java.io.File
import javax.imageio.ImageIO
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sin

val src = ImageIO.read(File(args.getOrElse(0) { "biker-src.png" }))
val out = File(args.getOrElse(1) { "anim" })

val W = 1080
val H = 1260
val D = 760.0     // диаметр круга на кадре
val CX = 540.0    // центр круга
val CY = 440.0    // от верхнего края (в Java2D ось Y смотрит вниз)
val FPS = 30

// Вырезаем круг: всё за пределами круга прозрачное, белый фон исходника уходит
val disc: BufferedImage = run {
    val s = src.width
    val img = BufferedImage(s, s, BufferedImage.TYPE_INT_ARGB)
    val g = img.createGraphics()
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON)
    val r = s / 2.0 - 3   // внешний край чёрной обводки
    g.clip = Ellipse2D.Double(s / 2.0 - r, s / 2.0 - r, 2 * r, 2 * r)
    g.drawImage(src, 0, 0, null)
    g.dispose()
    img
}

val green = Color(0x3D, 0xDC, 0x84)   // фирменный зелёный Android
val font = Font(Font.MONOSPACED, Font.BOLD, 104)

// Полосы скорости слева от круга: байкер едет вправо, воздух уносится назад, влево
fun speedLines(g: java.awt.Graphics2D, x0: Double, y0: Double, phase: Double, alpha: Double) {
    val rows = listOf(Triple(-250.0, 220.0, 0.0), Triple(-150.0, 320.0, 0.35), Triple(-40.0, 260.0, 0.7),
                      Triple(70.0, 340.0, 0.15), Triple(180.0, 240.0, 0.55), Triple(260.0, 180.0, 0.85))
    g.stroke = BasicStroke(7f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND)
    for ((dy, len, off) in rows) {
        val p = (phase + off) % 1.0
        val xr = x0 - D / 2 + 40 - p * 420
        val a = (alpha * (1 - p) * 0.85).coerceIn(0.0, 1.0)
        g.color = Color(1f, 1f, 1f, a.toFloat())
        val y = y0 - dy   // dy задан “вверх”, переводим в координаты Java2D
        g.drawLine(xr.toInt(), y.toInt(), (xr - len).toInt(), y.toInt())
    }
}

val red = Color(0xE5, 0x39, 0x35)
val TEXT = "red_byte"
fun lerp(a: Double, b: Double, t: Double) = a + (b - a) * t
fun mix(c1: Color, c2: Color, t: Double) = Color(
    lerp(c1.red.toDouble(), c2.red.toDouble(), t).toInt(),
    lerp(c1.green.toDouble(), c2.green.toDouble(), t).toInt(),
    lerp(c1.blue.toDouble(), c2.blue.toDouble(), t).toInt())
fun smooth(t: Double) = t.coerceIn(0.0, 1.0).let { it * it * (3 - 2 * it) }

// Надпись во время въезда: сначала красная “R”, потом из неё по буквам
// расползаются в стороны буквы red_byte и по дороге зеленеют.
// s: 0..0.3 “R” проявляется, 0.3..1 буквы разъезжаются по местам.
fun intro(g: java.awt.Graphics2D, s: Double) {
    g.font = font
    val fm = g.fontMetrics
    val baseline = H - 150
    val total = fm.stringWidth(TEXT)
    val left = (W - total) / 2.0
    val center = W / 2.0
    if (s < 0.3) {
        val a = smooth(s / 0.3)
        val big = font.deriveFont((104 * lerp(1.6, 1.25, a)).toFloat())
        g.font = big
        val w = g.fontMetrics.stringWidth("R")
        g.color = Color(red.red, red.green, red.blue, (255 * a).toInt())
        g.drawString("R", (center - w / 2).toFloat(), baseline.toFloat())
        return
    }
    val k = smooth((s - 0.3) / 0.7)
    // “R” гаснет и сжимается, пока буквы выезжают
    if (k < 1) {
        g.font = font.deriveFont((104 * 1.25 * (1 - 0.5 * k)).toFloat())
        val w = g.fontMetrics.stringWidth("R")
        g.color = Color(red.red, red.green, red.blue, (255 * (1 - k)).toInt())
        g.drawString("R", (center - w / 2).toFloat(), baseline.toFloat())
    }
    g.font = font
    var x = left
    for (ch in TEXT) {
        val cw = fm.charWidth(ch)
        val targetCenter = x + cw / 2.0
        // каждая буква стартует из центра; дальние начинают чуть позже
        val delay = kotlin.math.abs(targetCenter - center) / (total / 2.0) * 0.25
        val kk = smooth((k - delay) / (1 - delay))
        val cx = lerp(center, targetCenter, kk)
        val c = mix(red, green, kk)
        g.color = Color(c.red, c.green, c.blue, (255 * smooth(kk * 3)).toInt())
        g.drawString(ch.toString(), (cx - cw / 2).toFloat(), baseline.toFloat())
        x += cw
    }
}

fun frame(dx: Double, dy: Double, angleDeg: Double, phase: Double, linesAlpha: Double, textAlpha: Double,
          introStep: Double? = null): BufferedImage {
    val img = BufferedImage(W, H, BufferedImage.TYPE_INT_RGB)   // фон чёрный, как у экрана загрузки
    val g = img.createGraphics()
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON)
    g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC)
    g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON)
    val x = CX + dx
    val y = CY - dy
    speedLines(g, x, y, phase, linesAlpha)
    val saved = g.transform
    g.translate(x, y)
    g.rotate(-angleDeg * PI / 180)
    g.drawImage(disc, (-D / 2).toInt(), (-D / 2).toInt(), D.toInt(), D.toInt(), null)
    g.transform = saved
    if (introStep != null) {
        intro(g, introStep)
    } else if (textAlpha > 0) {
        g.font = font
        g.color = Color(green.red, green.green, green.blue, (255 * textAlpha.coerceIn(0.0, 1.0)).toInt())
        val text = "red_byte"
        val w = g.fontMetrics.stringWidth(text)
        g.drawString(text, (W - w) / 2, H - 150)
    }
    g.dispose()
    return img
}

fun save(img: BufferedImage, part: String, i: Int) {
    val dir = File(out, part).apply { mkdirs() }
    ImageIO.write(img, "png", File(dir, "%05d.png".format(i)))
}

// part0 (1,5 с): за первую секунду байкер въезжает слева и тормозит с лёгким клевком,
// а под ним красная “R” по буквам расползается в зелёную надпись red_byte
val INTRO = FPS * 3 / 2
for (i in 0 until INTRO) {
    val t = (i / (FPS - 1.0)).coerceAtMost(1.0)            // фаза въезда
    val e = 1 - (1 - t).pow(3)                            // ease-out
    val dx = -(W / 2.0 + D / 2 + 40) * (1 - e)
    val lean = when {
        t < 0.85 -> -6 * (1 - t / 0.85)
        t < 1.0 -> 2.5 * sin((t - 0.85) / 0.15 * PI)
        else -> 0.0
    }
    val s = i / (INTRO - 1.0)                             // фаза надписи
    save(frame(dx, 0.0, lean, i / 10.0, 1 - t * 0.4, 1.0, introStep = s), "part0", i)
}
// part1: “едет на месте”, бесшовный цикл
for (i in 0 until FPS) {
    val t = i / FPS.toDouble()
    val bob = 3 * sin(2 * PI * t * 3) + 1.5 * sin(2 * PI * t * 5)
    val ang = 0.6 * sin(2 * PI * t * 2)
    save(frame(0.0, bob, ang, t * 3, 0.6, 1.0), "part1", i)
}
// desc.txt: размер и FPS, затем части: p <повторы> <пауза> <папка>, 0 повторов = до конца загрузки
File(out, "desc.txt").writeText("$W $H $FPS\np 1 0 part0\np 0 0 part1\n")
println("ok: ${File(out, "part0").list()!!.size} + ${File(out, "part1").list()!!.size} кадров в ${out.path}")
