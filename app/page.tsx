import Image from "next/image";
import styles from "./page.module.css";

export default function Home() {
  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <div className={styles.intro}>
          <h1>Hello Aish!</h1>
          <p>Welcome to Next.js app</p>
        </div>
      </main>
    </div>
  );
}
