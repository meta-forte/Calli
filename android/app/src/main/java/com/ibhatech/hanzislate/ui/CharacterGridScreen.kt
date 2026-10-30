package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ibhatech.hanzislate.R
import com.ibhatech.hanzislate.models.CharacterItem
import com.ibhatech.hanzislate.models.CharacterStore
import com.ibhatech.hanzislate.models.GridCellSize
import com.ibhatech.hanzislate.models.PreferenceStore
import com.ibhatech.hanzislate.services.AppUpdateService
import com.ibhatech.hanzislate.services.AudioPlayerService
import com.ibhatech.hanzislate.services.PracticeStorageService
import kotlinx.coroutines.launch

@Composable
fun CharacterGridScreen(
    store: CharacterStore,
    prefs: PreferenceStore,
    updateService: AppUpdateService,
    audioService: AudioPlayerService,
    practiceStorage: PracticeStorageService
) {
    val scope = rememberCoroutineScope()
    val sections by store.sectionsFlow.collectAsState()
    val matchedMeanings by store.matchedMeaningsFlow.collectAsState()
    val isLoading by store.isLoadingFlow.collectAsState()
    val selectedLevel by store.selectedLevelFlow.collectAsState()
    val searchQuery by store.searchQueryFlow.collectAsState()

    val hasUnreadUpdate by updateService.hasUnreadUpdateFlow.collectAsState()
    val showUpdateSheet by updateService.showUpdateSheetFlow.collectAsState()
    val isForcedUpdate by updateService.isForcedUpdateFlow.collectAsState()

    var selectedCharacter by remember { mutableStateOf<CharacterItem?>(null) }
    var isShowingAbout by remember { mutableStateOf(false) }
    var isShowingLegal by remember { mutableStateOf(false) }
    var isShowingDisplaySettings by remember { mutableStateOf(false) }
    var isMainMenuExpanded by remember { mutableStateOf(false) }
    var isLevelMenuExpanded by remember { mutableStateOf(false) }

    var cellSize by remember {
        mutableStateOf(
            GridCellSize.fromRawValue(
                prefs.getString(GridCellSize.storageKey, GridCellSize.defaultSize.rawValue)
            )
        )
    }

    val isSearching = searchQuery.trim().isNotEmpty()
    val displayedCharacters = remember(sections) { sections.flatMap { it.characters } }
    val displayedCount = displayedCharacters.size

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.AppBackground)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.AppBackground)
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Box(modifier = Modifier.align(Alignment.CenterStart)) {
                    IconButton(onClick = { isMainMenuExpanded = true }) {
                        Box {
                            Icon(
                                imageVector = Icons.Default.Menu,
                                contentDescription = "Main Menu",
                                tint = Color(0.25f, 0.25f, 0.25f, 1f)
                            )
                            if (hasUnreadUpdate) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .align(Alignment.TopEnd)
                                        .offset(x = 2.dp, y = (-2).dp)
                                        .clip(CircleShape)
                                        .background(Color.Red)
                                )
                            }
                        }
                    }

                    DropdownMenu(
                        expanded = isMainMenuExpanded,
                        onDismissRequest = { isMainMenuExpanded = false }
                    ) {
                        DropdownMenuItem(
                            text = {
                                Text(if (hasUnreadUpdate) "Update Available" else "Check for Updates")
                            },
                            leadingIcon = {
                                Icon(Icons.Default.Notifications, contentDescription = null)
                            },
                            onClick = {
                                isMainMenuExpanded = false
                                updateService.showUpdateSheet = true
                                scope.launch {
                                    updateService.checkForUpdates()
                                }
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("About") },
                            leadingIcon = { Icon(Icons.Default.Info, contentDescription = null) },
                            onClick = {
                                isMainMenuExpanded = false
                                isShowingAbout = true
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Legal") },
                            leadingIcon = { Icon(Icons.Default.Description, contentDescription = null) },
                            onClick = {
                                isMainMenuExpanded = false
                                isShowingLegal = true
                            }
                        )
                    }
                }

                Row(
                    modifier = Modifier.align(Alignment.Center),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.app_logo),
                        contentDescription = null,
                        modifier = Modifier
                            .size(26.dp)
                            .clip(RoundedCornerShape(6.dp))
                    )
                    Text(
                        text = "HanziSlate",
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = AppColors.PrimaryText
                    )
                }

                IconButton(
                    onClick = { isShowingDisplaySettings = true },
                    modifier = Modifier.align(Alignment.CenterEnd)
                ) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = "Display Settings",
                        tint = Color(0.25f, 0.25f, 0.25f, 1f)
                    )
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.AppBackground)
                    .padding(horizontal = 16.dp)
                    .padding(top = 4.dp, bottom = 10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White)
                        .border(1.dp, AppColors.BorderGray, RoundedCornerShape(10.dp))
                        .padding(horizontal = 10.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = null,
                        tint = Color(0.45f, 0.45f, 0.45f, 1f),
                        modifier = Modifier.size(18.dp)
                    )

                    Box(modifier = Modifier.weight(1f)) {
                        if (searchQuery.isEmpty()) {
                            Text(
                                text = "Search Hanzi, Pinyin, or English word",
                                fontSize = 15.sp,
                                color = Color(0.55f, 0.55f, 0.58f, 1f)
                            )
                        }
                        BasicTextField(
                            value = searchQuery,
                            onValueChange = { store.searchQuery = it },
                            singleLine = true,
                            textStyle = TextStyle(
                                fontSize = 15.sp,
                                color = AppColors.PrimaryText
                            ),
                            cursorBrush = SolidColor(AppColors.AccentBlue),
                            keyboardOptions = KeyboardOptions(
                                capitalization = KeyboardCapitalization.None,
                                autoCorrectEnabled = false,
                                imeAction = ImeAction.Search
                            ),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }

                    if (searchQuery.isNotEmpty()) {
                        Icon(
                            imageVector = Icons.Default.Cancel,
                            contentDescription = "Clear Search",
                            tint = Color(0.45f, 0.45f, 0.45f, 1f),
                            modifier = Modifier
                                .size(18.dp)
                                .clickable { store.searchQuery = "" }
                        )
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "HSK Level",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = AppColors.SecondaryText
                    )

                    Box {
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White)
                                .border(1.dp, AppColors.BorderGray, RoundedCornerShape(8.dp))
                                .clickable { isLevelMenuExpanded = true }
                                .padding(horizontal = 12.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = "Level $selectedLevel",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.PrimaryText
                            )
                            Icon(
                                imageVector = Icons.Default.UnfoldMore,
                                contentDescription = null,
                                tint = AppColors.AccentBlue,
                                modifier = Modifier.size(16.dp)
                            )
                        }

                        DropdownMenu(
                            expanded = isLevelMenuExpanded,
                            onDismissRequest = { isLevelMenuExpanded = false }
                        ) {
                            for (level in store.availableLevels) {
                                DropdownMenuItem(
                                    text = { Text("Level $level") },
                                    trailingIcon = {
                                        if (level == selectedLevel) {
                                            Icon(Icons.Default.Check, contentDescription = null)
                                        }
                                    },
                                    onClick = {
                                        isLevelMenuExpanded = false
                                        store.selectedLevel = level
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Text(
                        text = if (isSearching) {
                            countLabel(displayedCount, "result")
                        } else {
                            countLabel(displayedCount, "character")
                        },
                        fontSize = 13.sp,
                        color = AppColors.SecondaryText
                    )
                }
            }

            HorizontalDivider(color = Color.Black.copy(alpha = 0.06f), thickness = 1.dp)

            when {
                isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            CircularProgressIndicator(color = AppColors.AccentBlue)
                            Text(
                                text = "Loading characters...",
                                fontSize = 14.sp,
                                color = AppColors.SecondaryText
                            )
                        }
                    }
                }
                displayedCount == 0 -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.MenuBook,
                                contentDescription = null,
                                tint = Color(0.50f, 0.50f, 0.50f, 1f),
                                modifier = Modifier.size(40.dp)
                            )
                            Text(
                                text = "No characters found",
                                fontSize = 17.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.SecondaryText
                            )
                        }
                    }
                }
                else -> {
                    LazyVerticalGrid(
                        columns = GridCells.Adaptive(minSize = cellSize.minimumCellWidth.dp),
                        contentPadding = PaddingValues(
                            start = 16.dp,
                            end = 16.dp,
                            top = if (isSearching) 4.dp else 12.dp,
                            bottom = 16.dp
                        ),
                        horizontalArrangement = Arrangement.spacedBy(GridCellSize.gridSpacing.dp),
                        verticalArrangement = Arrangement.spacedBy(GridCellSize.gridSpacing.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        for (section in sections) {
                            if (isSearching) {
                                item(
                                    key = "header_${section.id}",
                                    span = { GridItemSpan(maxLineSpan) }
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .background(AppColors.AppBackground)
                                            .padding(top = 10.dp, bottom = 4.dp),
                                        verticalAlignment = Alignment.Bottom
                                    ) {
                                        Text(
                                            text = section.title,
                                            fontSize = 15.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = AppColors.PrimaryText
                                        )
                                        Spacer(modifier = Modifier.weight(1f))
                                        Text(
                                            text = countLabel(section.characters.size, "character"),
                                            fontSize = 13.sp,
                                            color = AppColors.SecondaryText
                                        )
                                    }
                                }
                            }

                            items(
                                items = section.characters,
                                key = { it.id }
                            ) { item ->
                                val meaningSubtitle = if (isSearching) matchedMeanings[item.id] else null
                                CharacterCellView(
                                    character = item,
                                    size = cellSize,
                                    meaningSubtitle = meaningSubtitle,
                                    onClick = { selectedCharacter = item }
                                )
                            }
                        }
                    }
                }
            }
        }

        selectedCharacter?.let { current ->
            val stroke = remember(current.hanzi) { store.strokeInfo(current.hanzi) }
            val currentIndex = displayedCharacters.indexOf(current)
            val prevCallback: (() -> Unit)? = if (currentIndex > 0) {
                { selectedCharacter = displayedCharacters[currentIndex - 1] }
            } else {
                null
            }
            val nextCallback: (() -> Unit)? = if (currentIndex >= 0 && currentIndex < displayedCharacters.size - 1) {
                { selectedCharacter = displayedCharacters[currentIndex + 1] }
            } else {
                null
            }

            CharacterDetailSheet(
                character = current,
                strokeInfo = stroke,
                prefs = prefs,
                audioService = audioService,
                practiceStorage = practiceStorage,
                onPrevious = prevCallback,
                onNext = nextCallback,
                onDismiss = { selectedCharacter = null }
            )
        }

        if (isShowingDisplaySettings) {
            DisplaySettingsSheet(
                cellSize = cellSize,
                onSelectCellSize = { newSize ->
                    cellSize = newSize
                    prefs.putString(GridCellSize.storageKey, newSize.rawValue)
                },
                onDismiss = { isShowingDisplaySettings = false }
            )
        }

        if (isShowingAbout) {
            AboutSheet(
                updateService = updateService,
                onDismiss = { isShowingAbout = false }
            )
        }

        if (isShowingLegal) {
            LegalSheet(onDismiss = { isShowingLegal = false })
        }

        if (showUpdateSheet) {
            UpdateSheetView(
                updateService = updateService,
                onDismiss = { updateService.dismissOptionalNotice() }
            )
        }

        if (isForcedUpdate) {
            ForcedUpdateView(updateService = updateService)
        }
    }
}

private fun countLabel(count: Int, noun: String): String {
    return "$count $noun${if (count == 1) "" else "s"}"
}
