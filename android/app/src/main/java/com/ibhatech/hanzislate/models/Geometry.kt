package com.ibhatech.hanzislate.models

data class Vec2(
    val x: Double,
    val y: Double
) {
    constructor(x: Int, y: Int) : this(x.toDouble(), y.toDouble())
    constructor(x: Float, y: Float) : this(x.toDouble(), y.toDouble())
}

data class CanvasSize(
    val width: Double,
    val height: Double
) {
    constructor(width: Int, height: Int) : this(width.toDouble(), height.toDouble())
    constructor(width: Float, height: Float) : this(width.toDouble(), height.toDouble())
}
