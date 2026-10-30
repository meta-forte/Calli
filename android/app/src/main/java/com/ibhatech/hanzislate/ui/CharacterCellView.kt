package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ibhatech.hanzislate.models.CharacterItem
import com.ibhatech.hanzislate.models.GridCellSize

@Composable
fun CharacterCellView(
    character: CharacterItem,
    size: GridCellSize = GridCellSize.defaultSize,
    meaningSubtitle: String? = null,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    val hasMeaning = !meaningSubtitle.isNullOrEmpty()
    val cardHeight = if (hasMeaning) size.searchCellHeight.dp else size.cellHeight.dp
    val shape = RoundedCornerShape(size.cornerRadius.dp)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(cardHeight)
            .clip(shape)
            .background(Color.White)
            .border(1.dp, AppColors.BorderGray, shape)
            .then(
                if (enabled) Modifier.clickable(onClick = onClick) else Modifier
            )
            .padding(horizontal = 6.dp)
            .semantics(mergeDescendants = true) {
                contentDescription = "${character.hanzi}, ${character.pinyin}"
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = character.hanzi,
            fontSize = size.hanziFontSize.sp,
            fontWeight = FontWeight.SemiBold,
            color = AppColors.PrimaryText,
            textAlign = TextAlign.Center,
            maxLines = 1
        )

        Text(
            text = character.pinyin,
            fontSize = size.pinyinFontSize.sp,
            fontWeight = FontWeight.Normal,
            color = AppColors.SecondaryText,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        if (!meaningSubtitle.isNullOrEmpty()) {
            Text(
                text = meaningSubtitle,
                fontSize = size.meaningFontSize.sp,
                fontWeight = FontWeight.Medium,
                color = AppColors.AccentBlue.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
