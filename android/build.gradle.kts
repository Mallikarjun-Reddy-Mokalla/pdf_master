plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        if (!plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            try {
                plugins.apply("org.jetbrains.kotlin.android")
            } catch (_: Throwable) {
            }
        }
    }

    val configureAndroid = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val methods = android.javaClass.methods
                val compileSdkMethod = methods.firstOrNull {
                    (it.name == "compileSdkVersion" || it.name == "setCompileSdkVersion" || it.name == "setCompileSdk") &&
                    it.parameterTypes.size == 1
                }
                if (compileSdkMethod != null) {
                    if (compileSdkMethod.parameterTypes[0] == Int::class.javaPrimitiveType) {
                        compileSdkMethod.invoke(android, 36)
                    } else if (compileSdkMethod.parameterTypes[0] == Integer::class.java) {
                        compileSdkMethod.invoke(android, Integer.valueOf(36))
                    }
                }
            } catch (_: Throwable) {
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }

    // Align Kotlin JVM target to 17 across all subproject tasks
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // Align Java compile compatibility to 17
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
