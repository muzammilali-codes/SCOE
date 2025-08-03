package com.example.tios

import android.R.attr.button
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CheckboxDefaults.colors
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

@Composable

fun subject11(navController: NavController) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally // Center buttons horizontally
        ) {
            val buttonModifier = Modifier
                .fillMaxWidth(0.4f) // 80% of screen width for equal size buttons
                .height(50.dp)

            val buttonColor = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400))

            Button(
                onClick = { navController.navigate("class11_physics") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("PHYSICS")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("class11_chemistry") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("CHEMISTRY")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("class11_maths") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("MATHEMATICS")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("class11_biology") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("BIOLOGY")
            }
        }
    }
}


@Composable
fun subject12(navController: NavController) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val buttonModifier = Modifier
                .fillMaxWidth(0.4f)
                .height(50.dp)

            val buttonColor = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400))

            Button(
                onClick = { navController.navigate("physics12") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("PHYSICS")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("chemistry12") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("CHEMISTRY")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("maths12") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("MATHEMATICS")
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = { navController.navigate("biology12") },
                colors = buttonColor,
                modifier = buttonModifier
            ) {
                Text("BIOLOGY")
            }
        }
    }
}


