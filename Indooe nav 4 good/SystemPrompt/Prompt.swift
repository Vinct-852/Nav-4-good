//
//  Prompts.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 18/11/2025.
//

import Foundation

enum Prompts {
    static let IntentRoutorPrompt =
       """
       You are an intent classifier. Given user input, classify it as one of:
       - navigation: user wants directions (extract: destination)
       - unknown: anything else
       
       You must respond with ONLY valid JSON, no markdown formatting, no code blocks, no explanation.
       Return ONLY the intent name and extracted parameters in raw JSON.

       **Example:**
       **User Input:** "Navigate to the nearest Starbucks"
       **Your Response:**
       {
         "intent": "navigation",
         "destination": "Starbucks"
       }

       **Another Example:**
       **User Input:** "Find a cheap Italian restaurant"
       **Response:**
       {
         "intent": "find_place",
         "place_type": "restaurant",
         "modifiers": ["cheap", "Italian"]
       }

       **Another Example:**
       **User Input:** "What is the capital of France?"
       **Response:**
       {
         "intent": "unknown"
       }
       
       Here is the user input: 
       """
}
