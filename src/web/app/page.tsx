import HealthPanel from "./health-panel";
import { ja } from "../lib/ja";
export default function Home() {
  return <main><p className="eyebrow">GenAI Course Studio</p><h1>{ja.title}</h1><p>{ja.description}</p><HealthPanel /><p>{ja.disabled}</p><p className="note">{ja.scope}</p></main>;
}
