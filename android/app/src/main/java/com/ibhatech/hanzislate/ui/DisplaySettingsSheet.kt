package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ibhatech.hanzislate.models.CharacterItem
import com.ibhatech.hanzislate.models.GridCellSize

private val previewCharacters = listOf(
    CharacterItem(id = -1, level = 1, hanzi = "爱", pinyin = "ài", tones = "4", meaning = "", exampleChinese = "", examplePinyin = "", exampleEnglish = ""),
    CharacterItem(id = -2, level = 1, hanzi = "床", pinyin = "chuáng", tones = "2", meaning = "", exampleChinese = "", examplePinyin = "", exampleEnglish = ""),
    CharacterItem(id = -3, level = 1, hanzi = "都", pinyin = "dōu, dū", tones = "1", meaning = "", exampleChinese = "", examplePinyin = "", exampleEnglish = "")
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DisplaySettingsSheet(
    cellSize: GridCellSize,
    onSelectCellSize: (GridCellSize) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = AppColors.AppBackground
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.AppBackground)
                .padding(horizontal = 20.dp)
                .padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Display",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.PrimaryText,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.align(Alignment.Center)
                )
                Text(
                    text = "Done",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.AccentBlue,
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .clickable(onClick = onDismiss)
                        .padding(4.dp)
                )
            }

            Text(
                text = "Character Size",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = AppColors.SecondaryText
            )

            SegmentedPicker(
                options = GridCellSize.entries,
                selected = cellSize,
                label = { it.title },
                onSelect = onSelectCellSize,
                modifier = Modifier.fillMaxWidth()
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(GridCellSize.LARGE.cellHeight.dp),
                horizontalArrangement = Arrangement.spacedBy(GridCellSize.gridSpacing.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (item in previewCharacters) {
                    Box(modifier = Modifier.width((cellSize.minimumCellWidth + 8f).dp)) {
                        CharacterCellView(
                            character = item,
                            size = cellSize,
                            enabled = false,
                            onClick = {}
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))
        }
    }
}
