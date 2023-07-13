import Image from "next/image";
import { getVisits } from "./repository/visits";

export const revalidate = 0;

export default async function Home() {
  const visits = await getVisits();
  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <div className="relative flex place-items-center">
        <Image
          className="relative"
          src="/landbot.png"
          alt="Landbot Logo"
          width={180}
          height={37}
          priority
        />
      </div>

      <div className="flex flex-col items-center mt-20">
        <h1 className="text-4xl font-bold text-center">
          Welcome to the Landbot SRE Challenge!
        </h1>
        <p className="mt-10">
          You are today&apos;s visitor number{" "}
          <span className="font-bold">{visits.visits}</span> .
        </p>
        <p className="mt-10">
          Last Visit was at{" "}
          <span className="font-bold">{visits.lastVisit}</span> .
        </p>
      </div>
    </main>
  );
}
