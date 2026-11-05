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
            var configured = false
            // 1. Try int/Integer parameter first
            for (m in android.javaClass.methods) {
                if ((m.name == "compileSdkVersion" || m.name == "setCompileSdkVersion" || m.name == "setCompileSdk") && m.parameterTypes.size == 1) {
                    if (m.parameterTypes[0] == Int::class.javaPrimitiveType || m.parameterTypes[0] == java.lang.Integer::class.java) {
                        try {
                            m.invoke(android, 36)
                            configured = true
                            println("[build.gradle.kts] Set compileSdk=36 for \${project.name} using \${m.name}(int)")
                            break
                        } catch (e: Throwable) {
                            println("[build.gradle.kts] Failed \${m.name}(int) on \${project.name}: \${e.message}")
                        }
                    }
                }
            }
            // 2. If not configured, try String parameter
            if (!configured) {
                for (m in android.javaClass.methods) {
                    if ((m.name == "compileSdkVersion" || m.name == "setCompileSdkVersion" || m.name == "setCompileSdk") && m.parameterTypes.size == 1) {
                        if (m.parameterTypes[0] == String::class.java) {
                            try {
                                m.invoke(android, "android-36")
                                configured = true
                                println("[build.gradle.kts] Set compileSdk=android-36 for \${project.name} using \${m.name}(String)")
                                break
                            } catch (e: Throwable) {
                                println("[build.gradle.kts] Failed \${m.name}(String) on \${project.name}: \${e.message}")
                            }
                        }
                    }
                }
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
