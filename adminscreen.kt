package com.example.tios

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController

@Composable
fun adminscreen(navController: NavController) {
    val buttonColor = ButtonDefaults.buttonColors(containerColor = Color(0xFF006400))
    var password by remember { mutableStateOf("") }
    var error by remember { mutableStateOf(false) }
    val correctPassword = "admin123"

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(text = "Enter Password",
            color =  Color(0xFF006400),
            fontSize = 20.sp
         )
        Spacer(modifier = Modifier.height(20.dp))

        TextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation()
        )

        Spacer(modifier = Modifier.height(20.dp))

        Button(onClick = {
            if (password == correctPassword) {
              //  error = false
                navController.navigate("admin_upload")
            } else {

            error = true
            }
        },
            colors = buttonColor) {
            Text("Login")
        }

     if (error) {

            Spacer(modifier = Modifier.height(10.dp))
            Text("Incorrect password", color = Color.Red)

        }
    }
}
