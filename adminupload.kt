package com.example.tios

import PdfViewerScreen
import android.R.attr.button
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import kotlinx.coroutines.NonDisposableHandle.parent

data class DocumentItem(
    val id: String,
    val title: String,
    val link: String,
    val clazz: String,
    val subject: String
)

/*fun convertDriveLinkToViewable(link: String): String? {
    val fileIdRegex = Regex("""/d/([a-zA-Z0-9_-]+)""")
    val altFileIdRegex = Regex("""id=([a-zA-Z0-9_-]+)""")

    val fileId = fileIdRegex.find(link)?.groupValues?.get(1)
        ?: altFileIdRegex.find(link)?.groupValues?.get(1)

    return fileId?.let {
        "https://docs.google.com/gview?embedded=true&url=https://drive.google.com/uc?export=download&id=$it"
    }
}*/

@Composable
fun AdminUploadScreen()
{
    val buttonColor = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400))
    val context = LocalContext.current
    val firestore = Firebase.firestore

    var title by remember { mutableStateOf("") }
    var link by remember { mutableStateOf("") }
    var selectedClass by remember { mutableStateOf("11") }
    var selectedSubject by remember { mutableStateOf("PHYSICS") }
    var documents by remember { mutableStateOf<List<DocumentItem>>(emptyList()) }
    var expandedDocId by remember { mutableStateOf<String?>(null) }

    val classOptions = listOf("11", "12")
    val subjectOptions = listOf("PHYSICS", "CHEMISTRY", "MATHEMATICS", "BIOLOGY")

    // Fetch documents once
    LaunchedEffect(Unit) {
        firestore.collection("documents")
            .get()
            .addOnSuccessListener { result ->
                documents = result.documents.mapNotNull {
                    val t = it.getString("title") ?: return@mapNotNull null
                    val l = it.getString("link") ?: return@mapNotNull null
                    val c = it.getString("class") ?: ""
                    val s = it.getString("subject") ?: ""
                    DocumentItem(it.id, t, l, c, s)
                }
            }
    }

    Column(modifier = Modifier.padding(16.dp),
        verticalArrangement = Arrangement.Center, // Center vertically
        horizontalAlignment = Alignment.CenterHorizontally // Center horizontally
    )
    {
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("PDF Title") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = link,
            onValueChange = { link = it },
            label = { Text("Google Drive Link") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        DropdownField("Select Class", selectedClass, classOptions) { selectedClass = it }
        Spacer(modifier = Modifier.height(8.dp))
        DropdownField("Select Subject", selectedSubject, subjectOptions) { selectedSubject = it }

        Spacer(modifier = Modifier.height(16.dp))

        Button(onClick = {
            if (title.isNotBlank() && link.isNotBlank()) {
                val fileId = link.substringAfter("/d/").substringBefore("/")
                val previewUrl = "https://drive.google.com/file/d/$fileId/preview"


                if (previewUrl != null && link.startsWith("https://drive.google.com/file/d/") && link.contains("/view")&& fileId.isNotBlank()) {
                    val data = hashMapOf(
                        "title" to title,
                        "link" to previewUrl,
                        "class" to selectedClass,
                        "subject" to selectedSubject,
                        "secretKey" to "admin123"
                    )

                    firestore.collection("documents").add(data)
                        .addOnSuccessListener {
                            Toast.makeText(context, "Uploaded successfully", Toast.LENGTH_SHORT).show()


                            // 🔔 Notification entry for students
                            val notification = mapOf(
                                "title" to "📚 New Document Uploaded",
                                "body" to "$selectedSubject for Class $selectedClass",
                                "timestamp" to com.google.firebase.firestore.FieldValue.serverTimestamp(),
                                "secretKey" to "admin123"
                            )
                            firestore.collection("notifications").add(notification)

                            title = ""
                            link = ""
                            // Reload documents
                            firestore.collection("documents").get().addOnSuccessListener { result ->
                                documents = result.documents.mapNotNull {
                                    val t = it.getString("title") ?: return@mapNotNull null
                                    val l = it.getString("link") ?: return@mapNotNull null
                                    val c = it.getString("class") ?: ""
                                    val s = it.getString("subject") ?: ""
                                    DocumentItem(it.id, t, l, c, s)
                                }
                            }
                        }
                }
                else
                {
                    Toast.makeText(context, "Invalid Google Drive link", Toast.LENGTH_SHORT).show()
                }
            }
            else
            {
                Toast.makeText(context, "Please fill all fields", Toast.LENGTH_SHORT).show()
            }
        },
            colors = buttonColor)
        {
            Text("Upload PDF")
        }

        Spacer(modifier = Modifier.height(24.dp))
        Divider()
        Spacer(modifier = Modifier.height(8.dp))

        Text("Uploaded Documents", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        if (documents.isEmpty())
        {
            Text("No documents uploaded yet.")
        }
        else
        {
            LazyColumn {
                items(documents) { doc ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable {
                                        expandedDocId = if (expandedDocId == doc.id) null else doc.id
                                    }
                            ) {
                                Text(doc.title, style = MaterialTheme.typography.bodyLarge)
                                Text(
                                    "Class: ${doc.clazz}, Subject: ${doc.subject}",
                                    style = MaterialTheme.typography.labelMedium
                                )
                            }

                            Button(
                                onClick = {
                                    firestore.collection("documents")
                                        .document(doc.id)
                                        .delete()
                                        .addOnSuccessListener {
                                            documents = documents.filterNot { it.id == doc.id }
                                            Toast.makeText(context, "Deleted", Toast.LENGTH_SHORT).show()
                                        }
                                },
                                colors = buttonColor
                            ) {
                                Text("Delete", color = MaterialTheme.colorScheme.onError)
                            }
                        }

                        // Show WebView if this document is selected
                        if (expandedDocId == doc.id)
                        {
                            Spacer(modifier = Modifier.height(8.dp))
                            PdfViewerScreen(doc.link)
                        /*    AndroidView(
                                factory = { context ->
                                    WebView(context).apply {
                                        settings.javaScriptEnabled = true
                                        settings.domStorageEnabled = true
                                        webViewClient = WebViewClient()
                                        loadUrl(doc.link)
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(400.dp)
                            )*/
                        }

                        Divider(modifier = Modifier.padding(top = 8.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun DropdownField(label: String, selected: String, options: List<String>, onSelect: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val buttonColor = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400))


        Column(modifier = Modifier, verticalArrangement = Arrangement.Center) {
            Text(label, style = MaterialTheme.typography.labelMedium)
            Spacer(modifier = Modifier.height(4.dp))
            Button(
                onClick = { expanded = true },
                colors = buttonColor,

            ) {
                Text(selected)
            }
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                options.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option) },
                        onClick = {
                            onSelect(option)
                            expanded = false
                        }
                    )
                }
            }
        }
    }

