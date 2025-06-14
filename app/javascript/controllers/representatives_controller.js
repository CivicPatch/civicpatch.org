import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Representatives controller connected")
  }

  // Called before the frame is rendered
  beforeRender() {
    console.log("Before render")
  }

  // Called after the frame is loaded
  afterLoad() {
    console.log("After load")
  }
} 
