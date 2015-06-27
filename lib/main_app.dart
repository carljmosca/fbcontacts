// Copyright (c) 2015, Carl J. Mosca. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;

import 'package:polymer/polymer.dart';
import 'package:firebase/firebase.dart';
import 'package:paper_elements/paper_input.dart';
import 'package:paper_elements/paper_button.dart';
import 'package:core_elements/core_item.dart';
import 'package:core_elements/core_list_dart.dart';
import 'package:paper_elements/paper_toast.dart';
import 'package:observe/observe.dart';

const FB_BASE_ADDRESS = "https://stillhacking.firebaseio.com";
const PAGE_LIST = 0;
const PAGE_DETAILS = 1;

/// A Polymer `<main-app>` element.
@CustomTag('main-app')
class MainApp extends PolymerElement {
  @observable bool authenticated = false;
  @observable int selectedPage = 0;
  @observable Contact contactData = Contact.empty();
  
  @observable bool multi = false;
  @observable bool selectionEnabled = true;
  @observable ObservableList data;
  @observable var selection;
  int addIndex = 0;
  String uid;

  /// Constructor used to create instance of MainApp.
  MainApp.created() : super.created();
  
  Firebase firebase;
  PaperToast saveToast;
  CoreList coreListDart;
  PaperButton btnEdit;
  PaperButton btnDelete;

  void selectPage(html.Event e, var detail, html.Element target) {
   
    if (!authenticated) {
      return;
    }
    CoreItem btn = target;
    if (btn.id == "btn-details-menu") {
      selectedPage = PAGE_DETAILS;
    } else {
      selectedPage = PAGE_LIST;
    }

  }

  void inputHandler(html.Event e) {
      var inp = ($['zip'] as PaperInput);
      // very simple check - you can check what you want of courxe
      if(inp.value.length < 5) {
        // any text is treated as validation error
        inp.jsElement.callMethod('setCustomValidity', ["Give me more!"]);
      } else {
        // empty message text is interpreted as valid input
        inp.jsElement.callMethod('setCustomValidity', [""]);
      }
  }
  
  void editContact() {
    if (selection == null) {
      return;
    }
    Contact c = selection as Contact;
    contactData.key = c.key;
    contactData.company = c.company;
    contactData.firstName = c.firstName;
    contactData.lastName = c.lastName;
    contactData.address1 = c.address1;
    contactData.address2 = c.address2;
    contactData.city = c.city;
    contactData.state = c.state;
    contactData.zip = c.zip;
    contactData.email = c.email;
    contactData.telephone = c.telephone;
    contactData.mobile = c.mobile;
    selectedPage = PAGE_DETAILS;

  }
  
  void deleteContact(html.Event e, var detail, html.Element target) {
    
    if (selection == null) {
      return;
    }
    Contact c = selection as Contact;
    Firebase postRef = firebase.child("contacts/" + c.key);
    postRef.remove().then((onValue) {
      data.removeAt(c.index);      
    });
  }
    
  void saveContact(html.Event e, var detail, html.Element target) {
    
    if (!authenticated) {
      showMessage("Contacts cannot be saving without first logging in.");
      return;
    }
    
    var saveData = {
      'company': contactData.company, 
      'firstName': contactData.firstName, 
      'lastName': contactData.lastName,    
      'address1': contactData.address1, 
      'address2': contactData.address2, 
      'city': contactData.city,   
      'state': contactData.state, 
      'zip': contactData.zip, 
      'telephone': contactData.telephone,
      'email': contactData.email, 
      'mobile': contactData.mobile
      };
    
    Firebase saveRef;
    if (contactData.key != null && !contactData.key.isEmpty) {
      saveRef = firebase.child("contacts/" + contactData.key);
      saveRef.update(saveData).then((value) {
        showMessage("Contact was updated");  
      }).catchError((error) {
      });
    } else {
      saveRef = firebase.child("contacts");
      Firebase newPostRef = saveRef.push();    
      newPostRef.set(saveData).then((value) {
        String postId = newPostRef.key;
        if (postId != null) {
          contactData.key = postId;
        }
        showMessage("Contact was saved");  
      }).catchError((error) {
        showMessage("Error saving contact: " + error.toString());          
      });
    }
    
  }
  
  void loadContacts() {
    
    if (!authenticated) {
      return;
    }
    firebase.child("contacts").once("value").then((snapshot) {
      snapshot.forEach((snapshot) {
        data.insert(addIndex, new Contact(snapshot.key, snapshot.val()['company'], 
            snapshot.val()['firstName'], snapshot.val()['lastName'],
            snapshot.val()['address1'], snapshot.val()['address2'], 
            snapshot.val()['city'], snapshot.val()['state'], snapshot.val()['zip'],
            snapshot.val()['telephone'], snapshot.val()['email'], snapshot.val()['mobile'], 
            addIndex++));
      });
    });

   
  }
  
  void processValue() {
  
  }
  
  void showMessage(String text) {
    if (saveToast != null) {
      saveToast.text = text;
      saveToast.show();
    }
  }

  // Optional lifecycle methods - uncomment if needed.

//  /// Called when an instance of main-app is inserted into the DOM.
//  attached() {
//    super.attached();
//  }

//  /// Called when an instance of main-app is removed from the DOM.
//  detached() {
//    super.detached();
//  }

//  /// Called when an attribute (such as a class) of an instance of
//  /// main-app is added, changed, or removed.
//  attributeChanged(String name, String oldValue, String newValue) {
//    super.attributeChanges(name, oldValue, newValue);
//  }

  /// Called when main-app has been fully prepared (Shadow DOM created,
  /// property observers set up, event listeners attached).
  @override
  ready() {
    super.ready();
    data = new ObservableList();
    btnEdit = shadowRoot.querySelector("#btn-edit");
    //btnEdit.disabled = true;
    btnDelete = shadowRoot.querySelector("#btn-delete");
    //btnDelete.disabled = true;
    saveToast = shadowRoot.querySelector('#save-toast');
    coreListDart = shadowRoot.querySelector('#list');
    coreListDart.onSelectStart.listen((e) {
      resetListButtons();
    });
    firebase = new Firebase(FB_BASE_ADDRESS);
    firebase.authWithOAuthPopup('google').then((authResponse) {  
      uid = authResponse['auth']['uid'];
      afterAuthentication();
    });    
    selection = Contact.empty();
  }  
  
  void resetListButtons() {
    btnEdit.disabled = (selection == null);  
    btnDelete.disabled = (selection == null);
  }
  
  void afterAuthentication() {
    authenticated = true;
    showMessage("Authenticated");
    loadContacts();    
  }
  
}

class Contact extends Observable {
  @observable String key;
  @observable String company;
  @observable String firstName;
  @observable String lastName;
  @observable String address1;
  @observable String address2;
  @observable String city;
  @observable String state;
  @observable String zip;
  @observable String telephone;
  @observable String email;
  @observable String mobile;
  @observable bool checked;
  @observable int index;
  
  Contact(this.key, this.company, this.firstName, this.lastName,
      this.address1, this.address2, this.city, this.state, this.zip, this.telephone,
      this.email, this.mobile, this.index) {

  }
  
  static Contact empty() {
    return new Contact("", "", "", "", "", "", "", "", "", "", "", "", 0);
  }
  
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> result = new Map<String, dynamic>();
    result['company'] = company;
    result['firstName'] = firstName;
    result['lastName'] = lastName;
    result['address1'] = address1;
    result['address2'] = address2;
    result['city'] = city;
    result['state'] = state;
    result['zip'] = zip;
    result['email'] = email;
    result['telephone'] = telephone;
    result['mobile'] = mobile;
    return result;
  }
}

main() => initPolymer();