package com.example.tios

import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore

// Data model
data class Subjectdocs(val title: String, val link: String)

// Class 11 Subjects
@Composable
fun physics(navController: NavController) {
    SubjectScreen(navController = navController, className = "11", subject = "PHYSICS")
}

@Composable
fun chemistry(navController: NavController) {
    SubjectScreen(navController = navController, className = "11", subject = "CHEMISTRY")
}

@Composable
fun maths(navController: NavController) {
    SubjectScreen(navController = navController, className = "11", subject = "MATHEMATICS")
}

@Composable
fun biology(navController: NavController) {
    SubjectScreen(navController = navController, className = "11", subject = "BIOLOGY")
}

// Class 12 Subjects
@Composable
fun physics12(navController: NavController) {
    SubjectScreen(navController = navController, className = "12", subject = "PHYSICS")
}

@Composable
fun chemistry12(navController: NavController) {
    SubjectScreen(navController = navController, className = "12", subject = "CHEMISTRY")
}

@Composable
fun maths12(navController: NavController) {
    SubjectScreen(navController = navController, className = "12", subject = "MATHEMATICS")
}

@Composable
fun biology12(navController: NavController) {
    SubjectScreen(navController = navController, className = "12", subject = "BIOLOGY")
}

// Common screen for all subjects
@Composable
fun SubjectScreen(
    navController: NavController,
    className: String,
    subject: String
) {
    val context = LocalContext.current
    var documents by remember { mutableStateOf<List<Subjectdocs>>(emptyList()) }
    val darkGreen = Color(0xFF006400)

    // Fetch documents from Firestore
    LaunchedEffect(className, subject) {
        Firebase.firestore.collection("documents")
            .whereEqualTo("class", className)
            .whereEqualTo("subject", subject)
            .get()
            .addOnSuccessListener { result ->
                documents = result.documents.mapNotNull {
                    val title = it.getString("title")
                    val link = it.getString("link")
                    if (title != null && link != null) {
                        Subjectdocs(title, link)
                    } else null
                }
            }
            .addOnFailureListener {
                Toast.makeText(context, "Failed to load documents", Toast.LENGTH_SHORT).show()
            }
    }

    // UI layout
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(darkGreen)
    ) {
        // Fixed heading
        Text(
            text = "$subject - Class $className",
            style = MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Bold,
                color = Color.White
            ),
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 24.dp)
        )

        // Content
        if (documents.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("No documents available.", color = Color.White)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(
                    top = 72.dp, // Space for heading
                    start = 16.dp,
                    end = 16.dp,
                    bottom = 16.dp
                ),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(documents) { doc ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                val cleanUrl = doc.link
                                navController.navigate("pdfViewer/${Uri.encode(cleanUrl)}")
                            },
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                    ) {
                        Text(
                            text = doc.title,
                            modifier = Modifier.padding(16.dp),
                            color = darkGreen,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }
    }
}
