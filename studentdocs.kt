package com.example.tios

import android.net.Uri
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore

@Composable
fun StudentDocsScreen(navController: NavController) {
    val firestore = Firebase.firestore
    var docs by remember { mutableStateOf<List<DocumentItem>>(emptyList()) }

    // Fetch documents from Firestore once
    LaunchedEffect(Unit) {
        firestore.collection("documents")
            .get()
            .addOnSuccessListener { result ->
                docs = result.documents.mapNotNull {
                    val title = it.getString("title") ?: return@mapNotNull null
                    val link = it.getString("link") ?: return@mapNotNull null
                    val clazz = it.getString("class") ?: ""
                    val subject = it.getString("subject") ?: ""
                    DocumentItem(it.id, title, link, clazz, subject)
                }
            }
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Color(0xFF006400)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Available Documents",
                style = MaterialTheme.typography.headlineSmall,
                color = Color.White,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            LazyColumn {
                items(docs) { doc ->
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = Color(0xFF1E1E1E),
                            contentColor = Color.White
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                            .clickable {
                                navController.navigate("pdfViewer/${Uri.encode(doc.link)}")
                            }
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(text = doc.title, style = MaterialTheme.typography.bodyLarge)
                            Text(text = "Class: ${doc.clazz}, Subject: ${doc.subject}", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
        }
    }
}
