package com.example.tios
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController

@Composable
fun classSelection(navController: NavController) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center // This centers the content
    ) {
        Column(modifier = Modifier,
            verticalArrangement = Arrangement.Center) {
            Button(
                onClick = { navController.navigate("subjects_11") },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400)),
                modifier = Modifier
            )

            {
                Text("Class 11")
            }
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                onClick = { navController.navigate("subject12") },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400)),
                modifier = Modifier
                //.fillMaxSize()
            ){
                Text("Class 12")
            }
        }

    }
}