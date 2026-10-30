package com.ibhatech.hanzislate.models

import androidx.compose.ui.graphics.Path
import kotlin.math.min

sealed class SvgPathCommand {
    data class MoveTo(val pt: Vec2) : SvgPathCommand()
    data class LineTo(val pt: Vec2) : SvgPathCommand()
    data class QuadTo(val control: Vec2, val end: Vec2) : SvgPathCommand()
    data class CubicTo(val control1: Vec2, val control2: Vec2, val end: Vec2) : SvgPathCommand()
    data object Close : SvgPathCommand()
}

object StrokePathParser {
    private val tokenRegex = Regex("""[A-Za-z]|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?""")

    fun parseCommands(svgPath: String, canvasSize: CanvasSize): List<SvgPathCommand> {
        val commands = mutableListOf<SvgPathCommand>()
        val side = min(canvasSize.width, canvasSize.height)
        val scale = side / 1024.0
        val offsetX = (canvasSize.width - side) / 2.0
        val offsetY = (canvasSize.height - side) / 2.0

        fun transformPoint(x: Double, y: Double): Vec2 {
            val screenX = offsetX + x * scale
            val screenY = offsetY + (900.0 - y) * scale
            return Vec2(screenX, screenY)
        }

        val tokens = tokenRegex.findAll(svgPath).map { it.value }.toList()
        var index = 0
        var currentCommand = ' '

        fun hasNextDouble(): Boolean {
            return index < tokens.size && tokens[index].firstOrNull()?.isLetter() == false
        }

        fun nextDouble(): Double? {
            if (!hasNextDouble()) return null
            return tokens[index++].toDoubleOrNull()
        }

        while (index < tokens.size) {
            val token = tokens[index]
            if (token.first().isLetter()) {
                currentCommand = token.first()
                index++
            }

            when (currentCommand) {
                'M' -> {
                    val x = nextDouble()
                    val y = nextDouble()
                    if (x != null && y != null) {
                        commands.add(SvgPathCommand.MoveTo(transformPoint(x, y)))
                    }
                }
                'L' -> {
                    while (hasNextDouble()) {
                        val x = nextDouble()
                        val y = nextDouble()
                        if (x != null && y != null) {
                            commands.add(SvgPathCommand.LineTo(transformPoint(x, y)))
                        } else {
                            break
                        }
                    }
                }
                'Q' -> {
                    while (hasNextDouble()) {
                        val cx = nextDouble()
                        val cy = nextDouble()
                        val x = nextDouble()
                        val y = nextDouble()
                        if (cx != null && cy != null && x != null && y != null) {
                            commands.add(SvgPathCommand.QuadTo(transformPoint(cx, cy), transformPoint(x, y)))
                        } else {
                            break
                        }
                    }
                }
                'C' -> {
                    while (hasNextDouble()) {
                        val c1x = nextDouble()
                        val c1y = nextDouble()
                        val c2x = nextDouble()
                        val c2y = nextDouble()
                        val x = nextDouble()
                        val y = nextDouble()
                        if (c1x != null && c1y != null && c2x != null && c2y != null && x != null && y != null) {
                            commands.add(
                                SvgPathCommand.CubicTo(
                                    transformPoint(c1x, c1y),
                                    transformPoint(c2x, c2y),
                                    transformPoint(x, y)
                                )
                            )
                        } else {
                            break
                        }
                    }
                }
                'Z', 'z' -> {
                    commands.add(SvgPathCommand.Close)
                    currentCommand = ' '
                }
                else -> {
                    nextDouble()
                }
            }
        }

        return commands
    }

    fun parse(svgPath: String, canvasSize: CanvasSize): Path {
        val path = Path()
        for (cmd in parseCommands(svgPath, canvasSize)) {
            when (cmd) {
                is SvgPathCommand.MoveTo -> path.moveTo(cmd.pt.x.toFloat(), cmd.pt.y.toFloat())
                is SvgPathCommand.LineTo -> path.lineTo(cmd.pt.x.toFloat(), cmd.pt.y.toFloat())
                is SvgPathCommand.QuadTo -> path.quadraticTo(
                    cmd.control.x.toFloat(),
                    cmd.control.y.toFloat(),
                    cmd.end.x.toFloat(),
                    cmd.end.y.toFloat()
                )
                is SvgPathCommand.CubicTo -> path.cubicTo(
                    cmd.control1.x.toFloat(),
                    cmd.control1.y.toFloat(),
                    cmd.control2.x.toFloat(),
                    cmd.control2.y.toFloat(),
                    cmd.end.x.toFloat(),
                    cmd.end.y.toFloat()
                )
                SvgPathCommand.Close -> path.close()
            }
        }
        return path
    }
}
