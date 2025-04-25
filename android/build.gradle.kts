buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Keep the classpath for the Google Services plugin
        classpath("com.google.gms:google-services:4.4.1") // Use the latest version if needed
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Adjust the root build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Set up build directory per subproject
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Make sure :app is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}